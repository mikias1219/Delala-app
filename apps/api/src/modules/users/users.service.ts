import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ContactAccessService } from '../../common/services/contact-access.service';
import { UserRole } from '../../common/enums/user-role.enum';
import { UserStatus } from '../../common/enums/user-status.enum';
import { toPublicUser } from '../../common/utils/user.mapper';
import { TrustService } from '../trust/trust.service';
import { User } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private readonly usersRepo: Repository<User>,
    private readonly trustService: TrustService,
    private readonly contactAccess: ContactAccessService,
  ) {}

  async findById(id: string, viewerId?: string, viewerRole?: UserRole) {
    const user = await this.usersRepo.findOne({
      where: { id },
      relations: ['trustScore', 'workerProfile'],
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    const includePhone =
      viewerId === id ||
      viewerRole === UserRole.ADMIN ||
      (viewerId &&
        viewerRole &&
        (await this.contactAccess.canViewContact(viewerId, viewerRole, id)));

    const trustScore = await this.trustService.getForUser(id);
    return {
      ...toPublicUser(user, Boolean(includePhone)),
      trustScore,
      workerProfile: user.workerProfile,
    };
  }

  async getContact(viewerId: string, viewerRole: UserRole, targetId: string) {
    const target = await this.usersRepo.findOne({ where: { id: targetId } });
    if (!target) {
      throw new NotFoundException('User not found');
    }

    const allowed = await this.contactAccess.canViewContact(
      viewerId,
      viewerRole,
      targetId,
    );
    if (!allowed) {
      throw new ForbiddenException(
        'Contact info is available after a confirmed viewing or hire',
      );
    }

    return {
      id: target.id,
      phone: target.phone,
      fullName: target.fullName,
    };
  }

  async verifyUser(userId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    user.verifiedAt = new Date();
    if (user.status === UserStatus.PENDING) {
      user.status = UserStatus.ACTIVE;
    }
    await this.usersRepo.save(user);
    await this.trustService.recalculate(userId);
    return toPublicUser(user, true);
  }

  async suspendUser(userId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    user.status = UserStatus.SUSPENDED;
    await this.usersRepo.save(user);
    return toPublicUser(user, true);
  }

  async reinstateUser(userId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    user.status = UserStatus.ACTIVE;
    await this.usersRepo.save(user);
    await this.trustService.recalculate(userId);
    return toPublicUser(user, true);
  }
}
