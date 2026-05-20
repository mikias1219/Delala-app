import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../common/entities/base.entity';
import { ReviewEntityType } from '../../../common/enums/review-entity-type.enum';
import { User } from '../../users/entities/user.entity';

@Entity('reviews')
export class Review extends BaseEntity {
  @Column({ name: 'reviewer_id' })
  reviewerId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'reviewer_id' })
  reviewer: User;

  @Column({ name: 'reviewee_id' })
  revieweeId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'reviewee_id' })
  reviewee: User;

  @Column({ name: 'entity_type', type: 'enum', enum: ReviewEntityType })
  entityType: ReviewEntityType;

  @Column({ name: 'entity_id', type: 'uuid', nullable: true })
  entityId: string | null;

  @Column({ type: 'int' })
  rating: number;

  @Column({ type: 'text', nullable: true })
  comment: string | null;
}
