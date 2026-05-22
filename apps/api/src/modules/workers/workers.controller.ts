import { Body, Controller, Get, Put, Query } from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { UpsertWorkerProfileDto } from './dto/upsert-worker-profile.dto';
import { WorkersService } from './workers.service';

@Controller('workers')
export class WorkersController {
  constructor(private readonly workersService: WorkersService) {}

  @Roles(UserRole.EMPLOYER, UserRole.ADMIN)
  @Get()
  search(@Query('skills') skills?: string | string[]) {
    const skillList = !skills
      ? undefined
      : Array.isArray(skills)
          ? skills
          : skills.split(',').map((s) => s.trim()).filter(Boolean);
    return this.workersService.search(skillList);
  }

  @Roles(UserRole.WORKER, UserRole.ADMIN)
  @Get('me')
  me(@CurrentUser() user: JwtPayload) {
    return this.workersService.getMyProfile(user.sub);
  }

  @Roles(UserRole.WORKER, UserRole.ADMIN)
  @Put('me')
  upsert(@CurrentUser() user: JwtPayload, @Body() dto: UpsertWorkerProfileDto) {
    return this.workersService.upsertProfile(user.sub, dto);
  }
}
