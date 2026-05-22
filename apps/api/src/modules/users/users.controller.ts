import { Controller, ForbiddenException, Get, Param } from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { TrustService } from '../trust/trust.service';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly trustService: TrustService,
  ) {}

  @Get('me')
  me(@CurrentUser() user: JwtPayload) {
    return this.usersService.findById(user.sub);
  }

  @Get(':id/trust-score')
  async trustScore(
    @Param('id') id: string,
    @CurrentUser() current: JwtPayload,
  ) {
    if (current.role !== UserRole.ADMIN && current.sub !== id) {
      throw new ForbiddenException();
    }
    return this.trustService.getForUser(id);
  }
}
