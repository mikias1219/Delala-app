import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { CreateViewingDto } from './dto/create-viewing.dto';
import { ScheduleViewingDto } from './dto/schedule-viewing.dto';
import { ViewingsService } from './viewings.service';

@Controller('viewings')
export class ViewingsController {
  constructor(private readonly viewingsService: ViewingsService) {}

  @Roles(UserRole.RENTER)
  @Post()
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateViewingDto) {
    return this.viewingsService.createRequest(dto.propertyId, user.sub, dto.notes);
  }

  @Roles(UserRole.OWNER, UserRole.RENTER, UserRole.ADMIN)
  @Get()
  list(@CurrentUser() user: JwtPayload) {
    const role =
      user.role === UserRole.OWNER ? 'owner' : 'renter';
    return this.viewingsService.listForUser(user.sub, role);
  }

  @Roles(UserRole.OWNER)
  @Patch(':id/schedule')
  schedule(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
    @Body() dto: ScheduleViewingDto,
  ) {
    return this.viewingsService.schedule(id, user.sub, dto);
  }
}
