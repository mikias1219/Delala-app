import { Global, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Match } from '../modules/jobs/entities/match.entity';
import { ViewingRequest } from '../modules/viewings/entities/viewing-request.entity';
import { ContactAccessService } from './services/contact-access.service';

@Global()
@Module({
  imports: [TypeOrmModule.forFeature([ViewingRequest, Match])],
  providers: [ContactAccessService],
  exports: [ContactAccessService],
})
export class CommonModule {}
