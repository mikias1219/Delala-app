import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  Min,
  ValidateIf,
} from 'class-validator';
import { ReviewEntityType } from '../../../common/enums/review-entity-type.enum';

export class CreateReviewDto {
  @IsUUID()
  revieweeId: string;

  @IsEnum(ReviewEntityType)
  entityType: ReviewEntityType;

  @ValidateIf((o: CreateReviewDto) => o.entityType !== ReviewEntityType.USER)
  @IsUUID()
  entityId?: string;

  @IsInt()
  @Min(1)
  @Max(5)
  rating: number;

  @IsOptional()
  @IsString()
  comment?: string;
}
