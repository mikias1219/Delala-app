import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { toPublicUser } from '../../common/utils/user.mapper';
import { TrustService } from '../trust/trust.service';
import { User } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private readonly usersRepo: Repository<User>,
    private readonly trustService: TrustService,
  ) {}

  async findById(id: string) {
    const user = await this.usersRepo.findOne({
      where: { id },
      relations: ['trustScore', 'workerProfile'],
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    const trustScore = await this.trustService.getForUser(id);
    return {
      ...toPublicUser(user),
      trustScore,
      workerProfile: user.workerProfile,
    };
  }
}
