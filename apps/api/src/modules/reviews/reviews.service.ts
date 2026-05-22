import { BadRequestException, ForbiddenException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { ReviewEntityType } from '../../common/enums/review-entity-type.enum';
import { UserRole } from '../../common/enums/user-role.enum';
import { TrustService } from '../trust/trust.service';
import { User } from '../users/entities/user.entity';
import { CreateReviewDto } from './dto/create-review.dto';
import { Review } from './entities/review.entity';

@Injectable()
export class ReviewsService {
  constructor(
    @InjectRepository(Review) private readonly reviewsRepo: Repository<Review>,
    @InjectRepository(User) private readonly usersRepo: Repository<User>,
    private readonly trustService: TrustService,
  ) {}

  private assertReviewPermission(role: UserRole, entityType: ReviewEntityType) {
    const allowed: Partial<Record<UserRole, ReviewEntityType[]>> = {
      [UserRole.RENTER]: [ReviewEntityType.PROPERTY],
      [UserRole.OWNER]: [ReviewEntityType.USER],
      [UserRole.WORKER]: [ReviewEntityType.USER],
      [UserRole.EMPLOYER]: [ReviewEntityType.WORKER],
    };
    const types = allowed[role];
    if (!types?.includes(entityType)) {
      throw new ForbiddenException(
        `Role ${role} cannot submit reviews for entity type ${entityType}`,
      );
    }
  }

  async create(reviewerId: string, reviewerRole: UserRole, dto: CreateReviewDto) {
    if (reviewerRole === UserRole.ADMIN) {
      throw new ForbiddenException('Admins cannot submit reviews');
    }

    const reviewer = await this.usersRepo.findOne({ where: { id: reviewerId } });
    if (!reviewer?.verifiedAt && reviewerRole !== UserRole.RENTER) {
      throw new ForbiddenException('Verified account required to submit reviews');
    }

    if (reviewerId === dto.revieweeId) {
      throw new BadRequestException('Cannot review yourself');
    }

    this.assertReviewPermission(reviewerRole, dto.entityType);

    if (dto.entityType !== ReviewEntityType.USER && !dto.entityId) {
      throw new BadRequestException('entityId is required for this review type');
    }

    const duplicate = await this.reviewsRepo.findOne({
      where: {
        reviewerId,
        revieweeId: dto.revieweeId,
        entityType: dto.entityType,
        entityId: dto.entityId ? dto.entityId : IsNull(),
      },
    });
    if (duplicate) {
      throw new BadRequestException('You already submitted this review');
    }

    const review = this.reviewsRepo.create({
      reviewerId,
      revieweeId: dto.revieweeId,
      entityType: dto.entityType,
      entityId: dto.entityId ?? null,
      rating: dto.rating,
      comment: dto.comment ?? null,
    });
    const saved = await this.reviewsRepo.save(review);
    await this.trustService.recalculate(dto.revieweeId);
    return saved;
  }

  async listForUser(userId: string) {
    return this.reviewsRepo.find({
      where: { revieweeId: userId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }
}
