import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { MatchStatus } from '../../common/enums/match-status.enum';
import { ReviewEntityType } from '../../common/enums/review-entity-type.enum';
import { UserRole } from '../../common/enums/user-role.enum';
import { UserStatus } from '../../common/enums/user-status.enum';
import { ViewingStatus } from '../../common/enums/viewing-status.enum';
import { Match } from '../jobs/entities/match.entity';
import { Review } from '../reviews/entities/review.entity';
import { User } from '../users/entities/user.entity';
import { ViewingRequest } from '../viewings/entities/viewing-request.entity';
import { WorkerProfile } from '../workers/entities/worker-profile.entity';
import { TrustScore } from './entities/trust-score.entity';

export type TrustBreakdown = {
  identity: number;
  rating: number;
  completion: number;
  responseTime: number;
  profileCompleteness: number;
};

export type TrustBadge = 'trusted' | 'verified' | 'none' | 'warning' | 'suspended';

@Injectable()
export class TrustService {
  constructor(
    @InjectRepository(TrustScore)
    private readonly trustRepo: Repository<TrustScore>,
    @InjectRepository(User) private readonly usersRepo: Repository<User>,
    @InjectRepository(Review) private readonly reviewsRepo: Repository<Review>,
    @InjectRepository(ViewingRequest)
    private readonly viewingsRepo: Repository<ViewingRequest>,
    @InjectRepository(Match) private readonly matchesRepo: Repository<Match>,
    @InjectRepository(WorkerProfile)
    private readonly workersRepo: Repository<WorkerProfile>,
  ) {}

  badgeForScore(score: number, status: UserStatus): TrustBadge {
    if (status === UserStatus.SUSPENDED) return 'suspended';
    if (score >= 90) return 'trusted';
    if (score >= 70) return 'verified';
    if (score >= 50) return 'none';
    if (score >= 30) return 'warning';
    return 'suspended';
  }

  async getForUser(userId: string) {
    let score = await this.trustRepo.findOne({ where: { userId } });
    const stale =
      !score ||
      !score.lastRecalculatedAt ||
      Date.now() - score.lastRecalculatedAt.getTime() > 24 * 60 * 60 * 1000;

    if (stale) {
      return this.recalculate(userId);
    }
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    return {
      ...score,
      badge: this.badgeForScore(score!.score, user?.status ?? UserStatus.ACTIVE),
    };
  }

  async recalculate(userId: string) {
    const user = await this.usersRepo.findOne({
      where: { id: userId },
      relations: ['workerProfile'],
    });
    if (!user) {
      throw new Error('User not found for trust recalculation');
    }

    const breakdown = await this.computeBreakdown(user);
    const total = Math.min(
      100,
      Math.round(
        breakdown.identity +
          breakdown.rating +
          breakdown.completion +
          breakdown.responseTime +
          breakdown.profileCompleteness,
      ),
    );

    let record = await this.trustRepo.findOne({ where: { userId } });
    if (!record) {
      record = this.trustRepo.create({ userId });
    }
    record.score = total;
    record.breakdownJson = breakdown;
    record.lastRecalculatedAt = new Date();
    await this.trustRepo.save(record);

    if (total < 30 && user.status === UserStatus.ACTIVE) {
      user.status = UserStatus.SUSPENDED;
      await this.usersRepo.save(user);
    }

    return {
      ...record,
      badge: this.badgeForScore(total, user.status),
    };
  }

  private async computeBreakdown(user: User): Promise<TrustBreakdown> {
    const identity = user.verifiedAt ? 30 : 0;

    const reviews = await this.reviewsRepo.find({
      where: { revieweeId: user.id },
    });
    const rating =
      reviews.length >= 3
        ? (reviews.reduce((s, r) => s + r.rating, 0) / reviews.length / 5) * 25
        : 0;

    const completion = await this.computeCompletion(user);
    const responseTime = await this.computeResponseTime(user);
    const profileCompleteness = this.computeProfileCompleteness(user);

    return {
      identity,
      rating: Math.round(rating * 10) / 10,
      completion: Math.round(completion * 10) / 10,
      responseTime: Math.round(responseTime * 10) / 10,
      profileCompleteness,
    };
  }

  private async computeCompletion(user: User): Promise<number> {
    let completed = 0;
    let total = 0;

    if (user.role === UserRole.OWNER) {
      const viewings = await this.viewingsRepo
        .createQueryBuilder('v')
        .innerJoin('v.property', 'p')
        .where('p.ownerId = :userId', { userId: user.id })
        .getMany();
      total = viewings.length;
      completed = viewings.filter(
        (v) =>
          v.status === ViewingStatus.COMPLETED ||
          v.status === ViewingStatus.SCHEDULED,
      ).length;
    } else if (user.role === UserRole.RENTER) {
      const viewings = await this.viewingsRepo.find({
        where: { renterId: user.id },
      });
      total = viewings.length;
      completed = viewings.filter(
        (v) =>
          v.status === ViewingStatus.COMPLETED ||
          v.status === ViewingStatus.SCHEDULED,
      ).length;
    } else if (
      user.role === UserRole.WORKER ||
      user.role === UserRole.EMPLOYER
    ) {
      const qb = this.matchesRepo
        .createQueryBuilder('m')
        .innerJoin('m.jobPost', 'j');
      if (user.role === UserRole.WORKER) {
        qb.innerJoin('m.worker', 'w').where('w.userId = :userId', {
          userId: user.id,
        });
      } else {
        qb.where('j.employerId = :userId', { userId: user.id });
      }
      const matches = await qb.getMany();
      total = matches.length;
      completed = matches.filter(
        (m) =>
          m.status === MatchStatus.HIRED || m.status === MatchStatus.ENDED,
      ).length;
    }

    if (total === 0) return 10;
    return (completed / total) * 20;
  }

  private async computeResponseTime(user: User): Promise<number> {
    if (user.role === UserRole.OWNER) {
      const pending = await this.viewingsRepo
        .createQueryBuilder('v')
        .innerJoin('v.property', 'p')
        .where('p.ownerId = :userId', { userId: user.id })
        .andWhere('v.status = :status', { status: ViewingStatus.REQUESTED })
        .getCount();
      if (pending === 0) return 15;
      return Math.max(0, 15 - pending * 3);
    }
    return 10;
  }

  private computeProfileCompleteness(user: User): number {
    let pts = 0;
    if (user.fullName) pts += 3;
    if (user.phone) pts += 2;
    if (user.nationalIdUrl) pts += 2;
    const wp = user.workerProfile;
    if (wp) {
      if (wp.bio && wp.bio.length >= 10) pts += 1;
      if (wp.skills?.length) pts += 1;
      if (wp.availability) pts += 1;
    } else if (user.role !== UserRole.WORKER) {
      pts += 3;
    }
    return Math.min(10, pts);
  }
}
