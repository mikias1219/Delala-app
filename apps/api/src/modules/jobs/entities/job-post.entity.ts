import { Column, Entity, JoinColumn, ManyToOne, OneToMany } from 'typeorm';
import { BaseEntity } from '../../../common/entities/base.entity';
import { JobStatus } from '../../../common/enums/job-status.enum';
import { User } from '../../users/entities/user.entity';
import { Match } from './match.entity';

@Entity('job_posts')
export class JobPost extends BaseEntity {
  @Column({ name: 'employer_id' })
  employerId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'employer_id' })
  employer: User;

  @Column({ name: 'job_type' })
  jobType: string;

  @Column()
  location: string;

  @Column({ name: 'salary_offer', type: 'decimal', precision: 12, scale: 2, nullable: true })
  salaryOffer: string | null;

  @Column({ type: 'text', nullable: true })
  requirements: string | null;

  @Column({ type: 'enum', enum: JobStatus, default: JobStatus.OPEN })
  status: JobStatus;

  @OneToMany(() => Match, (match) => match.jobPost)
  matches: Match[];
}
