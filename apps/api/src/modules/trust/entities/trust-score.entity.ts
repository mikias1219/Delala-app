import { Column, Entity, JoinColumn, OneToOne } from 'typeorm';
import { BaseEntity } from '../../../common/entities/base.entity';
import { User } from '../../users/entities/user.entity';

@Entity('trust_scores')
export class TrustScore extends BaseEntity {
  @Column({ name: 'user_id', unique: true })
  userId: string;

  @OneToOne(() => User, (user) => user.trustScore)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'int', default: 50 })
  score: number;

  @Column({ name: 'last_recalculated_at', type: 'timestamptz', nullable: true })
  lastRecalculatedAt: Date | null;

  @Column({ name: 'breakdown_json', type: 'jsonb', nullable: true })
  breakdownJson: Record<string, number> | null;
}
