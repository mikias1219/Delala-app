import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NotificationsModule } from '../notifications/notifications.module';
import { Property } from '../properties/entities/property.entity';
import { ViewingRequest } from './entities/viewing-request.entity';
import { ViewingsController } from './viewings.controller';
import { ViewingsService } from './viewings.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([ViewingRequest, Property]),
    NotificationsModule,
  ],
  controllers: [ViewingsController],
  providers: [ViewingsService],
  exports: [ViewingsService],
})
export class ViewingsModule {}
