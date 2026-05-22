import {
  BadRequestException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { randomInt } from 'crypto';
import { Repository } from 'typeorm';
import { toPublicUser } from '../../common/utils/user.mapper';
import { UserRole } from '../../common/enums/user-role.enum';
import { UserStatus } from '../../common/enums/user-status.enum';
import { RedisService } from '../../redis/redis.service';
import { User } from '../users/entities/user.entity';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { JwtPayload } from './interfaces/jwt-payload.interface';

type OtpPayload = { code: string; role?: UserRole; isRegistration?: boolean };

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectRepository(User) private readonly usersRepo: Repository<User>,
    private readonly redis: RedisService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  private normalizePhone(phone: string): string {
    if (phone.startsWith('09')) {
      return `+251${phone.slice(1)}`;
    }
    return phone;
  }

  private otpKey(phone: string): string {
    return `otp:${phone}`;
  }

  async requestOtp(dto: RequestOtpDto): Promise<{ message: string; devCode?: string }> {
    const phone = this.normalizePhone(dto.phone);
    const existing = await this.usersRepo.findOne({ where: { phone } });

    if (dto.role === UserRole.ADMIN) {
      throw new BadRequestException('Admin accounts cannot be created via the app');
    }

    if (dto.isRegistration) {
      if (!dto.role) {
        throw new BadRequestException('Select an account type to register');
      }
      if (existing) {
        throw new BadRequestException(
          'This phone is already registered. Sign in instead.',
        );
      }
    } else if (existing && dto.role && dto.role !== existing.role) {
      throw new BadRequestException(
        'This phone is registered as a different account type. Sign in without changing role.',
      );
    }

    const code = String(randomInt(100000, 999999));
    const ttl = this.config.get<number>('otp.ttlSeconds') ?? 300;
    const payload: OtpPayload = {
      code,
      role: dto.role,
      isRegistration: dto.isRegistration,
    };
    await this.redis.set(this.otpKey(phone), JSON.stringify(payload), ttl);

    const devMode = this.config.get<boolean>('otp.devMode');
    if (devMode) {
      this.logger.log(`[DEV] OTP for ${phone}: ${code}`);
    } else {
      this.logger.warn(`SMS provider not configured — OTP for ${phone} not sent`);
    }

    return {
      message: 'OTP sent if the number is valid',
      ...(devMode ? { devCode: code } : {}),
    };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const phone = this.normalizePhone(dto.phone);
    const stored = await this.redis.get(this.otpKey(phone));

    if (!stored) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    let otpPayload: OtpPayload;
    try {
      otpPayload = JSON.parse(stored) as OtpPayload;
    } catch {
      otpPayload = { code: stored };
    }

    if (otpPayload.code !== dto.code) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    await this.redis.del(this.otpKey(phone));

    let user = await this.usersRepo.findOne({ where: { phone } });

    if (!user) {
      const role = dto.role ?? otpPayload.role ?? UserRole.RENTER;
      if (role === UserRole.ADMIN) {
        throw new BadRequestException('Invalid account type');
      }
      user = this.usersRepo.create({
        phone,
        role,
        status: UserStatus.ACTIVE,
      });
      await this.usersRepo.save(user);
    } else if (
      otpPayload.isRegistration ||
      (dto.role && dto.role !== user.role)
    ) {
      throw new BadRequestException(
        'This phone is already registered. Use Sign in.',
      );
    }

    if (user.status === UserStatus.SUSPENDED) {
      throw new BadRequestException('Account is suspended. Contact support.');
    }

    const payload: JwtPayload = {
      sub: user.id,
      phone: user.phone,
      role: user.role,
    };

    const accessToken = await this.jwt.signAsync(payload);
    return { accessToken, user: toPublicUser(user) };
  }
}
