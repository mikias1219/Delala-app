import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserRole } from '../../common/enums/user-role.enum';
import { User } from '../users/entities/user.entity';
import { UpsertWorkerProfileDto } from './dto/upsert-worker-profile.dto';
import { WorkerProfile } from './entities/worker-profile.entity';

@Injectable()
export class WorkersService {
  constructor(
    @InjectRepository(WorkerProfile)
    private readonly workersRepo: Repository<WorkerProfile>,
    @InjectRepository(User) private readonly usersRepo: Repository<User>,
  ) {}

  async search(skills?: string[]) {
    const qb = this.workersRepo
      .createQueryBuilder('w')
      .leftJoinAndSelect('w.user', 'user')
      .where('user.status = :status', { status: 'active' });

    if (skills?.length) {
      qb.andWhere('w.skills && :skills', { skills });
    }

    return qb.orderBy('w.ratingAvg', 'DESC').take(50).getMany();
  }

  async getMyProfile(userId: string) {
    const profile = await this.workersRepo.findOne({
      where: { userId },
      relations: ['user'],
    });
    if (!profile) {
      throw new NotFoundException('Worker profile not found');
    }
    return profile;
  }

  async upsertProfile(userId: string, dto: UpsertWorkerProfileDto) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    if (user.role !== UserRole.WORKER && user.role !== UserRole.ADMIN) {
      throw new BadRequestException('User must have worker role');
    }

    let profile = await this.workersRepo.findOne({ where: { userId } });
    if (!profile) {
      profile = this.workersRepo.create({ userId, skills: dto.skills });
    }

    profile.skills = dto.skills;
    profile.availability = dto.availability ?? null;
    profile.salaryExpectation =
      dto.salaryExpectation != null ? String(dto.salaryExpectation) : null;
    profile.bio = dto.bio ?? null;

    return this.workersRepo.save(profile);
  }
}
