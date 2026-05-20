import { Column, Entity, JoinColumn, OneToOne } from 'typeorm';
import { BaseEntity } from '../../../common/entities/base.entity';
import { User } from '../../users/entities/user.entity';

@Entity('worker_profiles')
export class WorkerProfile extends BaseEntity {
  @Column({ name: 'user_id', unique: true })
  userId: string;

  @OneToOne(() => User, (user) => user.workerProfile)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'text', array: true, default: [] })
  skills: string[];

  @Column({ type: 'varchar', length: 255, nullable: true })
  availability: string | null;

  @Column({ name: 'salary_expectation', type: 'decimal', precision: 12, scale: 2, nullable: true })
  salaryExpectation: string | null;

  @Column({ type: 'text', nullable: true })
  bio: string | null;

  @Column({ name: 'rating_avg', type: 'decimal', precision: 3, scale: 2, default: 0 })
  ratingAvg: string;
}
