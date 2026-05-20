import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { CreateJobDto } from './dto/create-job.dto';
import { JobsService } from './jobs.service';

@Controller('jobs')
export class JobsController {
  constructor(private readonly jobsService: JobsService) {}

  @Roles(UserRole.EMPLOYER)
  @Post()
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateJobDto) {
    return this.jobsService.create(user.sub, {
      jobType: dto.jobType,
      location: dto.location,
      requirements: dto.requirements ?? null,
      salaryOffer: dto.salaryOffer != null ? String(dto.salaryOffer) : undefined,
    });
  }

  @Roles(UserRole.EMPLOYER, UserRole.ADMIN)
  @Get('mine')
  listMine(@CurrentUser() user: JwtPayload) {
    return this.jobsService.listForEmployer(user.sub);
  }

  @Roles(UserRole.WORKER, UserRole.EMPLOYER, UserRole.ADMIN)
  @Get()
  listOpen() {
    return this.jobsService.listOpen();
  }

  @Roles(UserRole.WORKER, UserRole.ADMIN)
  @Post(':id/apply/:workerId')
  apply(
    @Param('id') jobId: string,
    @Param('workerId') workerId: string,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.jobsService.apply(jobId, workerId, user.sub, user.role);
  }
}
