import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JobStatus } from '../../common/enums/job-status.enum';
import { MatchStatus } from '../../common/enums/match-status.enum';
import { UserRole } from '../../common/enums/user-role.enum';
import { WorkerProfile } from '../workers/entities/worker-profile.entity';
import { JobPost } from './entities/job-post.entity';
import { Match } from './entities/match.entity';

@Injectable()
export class JobsService {
  constructor(
    @InjectRepository(JobPost) private readonly jobsRepo: Repository<JobPost>,
    @InjectRepository(Match) private readonly matchesRepo: Repository<Match>,
    @InjectRepository(WorkerProfile)
    private readonly workersRepo: Repository<WorkerProfile>,
  ) {}

  async create(
    employerId: string,
    data: {
      jobType: string;
      location: string;
      requirements?: string | null;
      salaryOffer?: string;
    },
  ) {
    const job = this.jobsRepo.create({
      employerId,
      jobType: data.jobType,
      location: data.location,
      requirements: data.requirements ?? null,
      salaryOffer: data.salaryOffer ?? null,
      status: JobStatus.OPEN,
    });
    return this.jobsRepo.save(job);
  }

  async listOpen() {
    return this.jobsRepo.find({
      where: { status: JobStatus.OPEN },
      order: { createdAt: 'DESC' },
    });
  }

  async listForEmployer(employerId: string) {
    return this.jobsRepo.find({
      where: { employerId },
      relations: ['matches', 'matches.worker', 'matches.worker.user'],
      order: { createdAt: 'DESC' },
    });
  }

  async apply(
    jobPostId: string,
    workerProfileId: string,
    requesterId: string,
    requesterRole: UserRole,
  ) {
    const job = await this.jobsRepo.findOne({ where: { id: jobPostId } });
    if (!job) {
      throw new NotFoundException('Job not found');
    }
    if (job.status !== JobStatus.OPEN) {
      throw new BadRequestException('Job is not open for applications');
    }

    const worker = await this.workersRepo.findOne({
      where: { id: workerProfileId },
    });
    if (!worker) {
      throw new NotFoundException('Worker profile not found');
    }

    if (requesterRole === UserRole.WORKER && worker.userId !== requesterId) {
      throw new ForbiddenException('Workers can only apply for themselves');
    }

    const existing = await this.matchesRepo.findOne({
      where: { jobPostId, workerId: workerProfileId },
    });
    if (existing) {
      throw new BadRequestException('Already applied to this job');
    }

    const match = this.matchesRepo.create({
      jobPostId,
      workerId: workerProfileId,
      status: MatchStatus.APPLIED,
    });
    return this.matchesRepo.save(match);
  }
}
