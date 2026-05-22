import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { CreatePropertyDto } from './dto/create-property.dto';
import { SearchPropertiesDto } from './dto/search-properties.dto';
import { UpdatePropertyDto } from './dto/update-property.dto';
import { PropertiesService } from './properties.service';

@Controller('properties')
export class PropertiesController {
  constructor(private readonly propertiesService: PropertiesService) {}

  @Public()
  @Get()
  search(@Query() query: SearchPropertiesDto) {
    return this.propertiesService.search(query);
  }

  @Roles(UserRole.OWNER, UserRole.ADMIN)
  @Get('mine')
  listMine(@CurrentUser() user: JwtPayload) {
    return this.propertiesService.listByOwner(user.sub);
  }

  @Public()
  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.propertiesService.findById(id);
  }

  @Roles(UserRole.OWNER, UserRole.ADMIN)
  @Post()
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreatePropertyDto) {
    return this.propertiesService.create(user.sub, dto);
  }

  @Roles(UserRole.OWNER, UserRole.ADMIN)
  @Patch(':id')
  update(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdatePropertyDto,
  ) {
    return this.propertiesService.update(id, user, dto);
  }

  @Roles(UserRole.ADMIN)
  @Post(':id/verify')
  verify(@Param('id') id: string) {
    return this.propertiesService.verify(id);
  }
}
