import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../common/entities/base.entity';
import { MatchStatus } from '../../../common/enums/match-status.enum';
import { WorkerProfile } from '../../workers/entities/worker-profile.entity';
import { JobPost } from './job-post.entity';

@Entity('matches')
export class Match extends BaseEntity {
  @Column({ name: 'job_post_id' })
  jobPostId: string;

  @ManyToOne(() => JobPost, (job) => job.matches)
  @JoinColumn({ name: 'job_post_id' })
  jobPost: JobPost;

  @Column({ name: 'worker_id' })
  workerId: string;

  @ManyToOne(() => WorkerProfile)
  @JoinColumn({ name: 'worker_id' })
  worker: WorkerProfile;

  @Column({ type: 'enum', enum: MatchStatus, default: MatchStatus.APPLIED })
  status: MatchStatus;

  @Column({ name: 'hired_at', type: 'timestamptz', nullable: true })
  hiredAt: Date | null;

  @Column({ name: 'ended_at', type: 'timestamptz', nullable: true })
  endedAt: Date | null;
}
