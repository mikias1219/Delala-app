import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { ReviewEntityType } from '../../common/enums/review-entity-type.enum';
import { CreateReviewDto } from './dto/create-review.dto';
import { Review } from './entities/review.entity';

@Injectable()
export class ReviewsService {
  constructor(
    @InjectRepository(Review) private readonly reviewsRepo: Repository<Review>,
  ) {}

  async create(reviewerId: string, dto: CreateReviewDto) {
    if (reviewerId === dto.revieweeId) {
      throw new BadRequestException('Cannot review yourself');
    }

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
    return this.reviewsRepo.save(review);
  }

  async listForUser(userId: string) {
    return this.reviewsRepo.find({
      where: { revieweeId: userId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }
}
