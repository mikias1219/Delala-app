import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { CreateReviewDto } from './dto/create-review.dto';
import { ReviewsService } from './reviews.service';

@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Roles(UserRole.RENTER, UserRole.OWNER, UserRole.WORKER, UserRole.EMPLOYER)
  @Post()
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateReviewDto) {
    return this.reviewsService.create(user.sub, user.role as UserRole, dto);
  }

  @Get('user/:userId')
  listForUser(@Param('userId') userId: string) {
    return this.reviewsService.listForUser(userId);
  }
}
