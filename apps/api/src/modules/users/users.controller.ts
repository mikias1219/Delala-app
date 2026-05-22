import {
  Controller,
  ForbiddenException,
  Get,
  Param,
  Post,
} from '@nestjs/common';
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
    return this.usersService.findById(
      user.sub,
      user.sub,
      user.role as UserRole,
    );
  }

  @Get(':id/contact')
  contact(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.usersService.getContact(
      user.sub,
      user.role as UserRole,
      id,
    );
  }

  @Roles(UserRole.ADMIN)
  @Post(':id/verify')
  verifyUser(@Param('id') id: string) {
    return this.usersService.verifyUser(id);
  }

  @Roles(UserRole.ADMIN)
  @Post(':id/suspend')
  suspendUser(@Param('id') id: string) {
    return this.usersService.suspendUser(id);
  }

  @Roles(UserRole.ADMIN)
  @Post(':id/reinstate')
  reinstateUser(@Param('id') id: string) {
    return this.usersService.reinstateUser(id);
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
