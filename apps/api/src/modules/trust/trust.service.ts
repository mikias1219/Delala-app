import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TrustScore } from './entities/trust-score.entity';

const DEFAULT_BREAKDOWN = {
  identity: 0,
  rating: 0,
  completion: 0,
  responseTime: 0,
  profileCompleteness: 0,
};

@Injectable()
export class TrustService {
  constructor(
    @InjectRepository(TrustScore)
    private readonly trustRepo: Repository<TrustScore>,
  ) {}

  async getForUser(userId: string) {
    let score = await this.trustRepo.findOne({ where: { userId } });
    if (!score) {
      try {
        score = this.trustRepo.create({
          userId,
          score: 50,
          breakdownJson: { ...DEFAULT_BREAKDOWN },
          lastRecalculatedAt: new Date(),
        });
        await this.trustRepo.save(score);
      } catch {
        score = await this.trustRepo.findOne({ where: { userId } });
        if (!score) {
          throw new Error('Failed to initialize trust score');
        }
      }
    }
    return score;
  }
}
