import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Match } from '../jobs/entities/match.entity';
import { Review } from '../reviews/entities/review.entity';
import { User } from '../users/entities/user.entity';
import { ViewingRequest } from '../viewings/entities/viewing-request.entity';
import { WorkerProfile } from '../workers/entities/worker-profile.entity';
import { TrustScore } from './entities/trust-score.entity';
import { TrustService } from './trust.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      TrustScore,
      User,
      Review,
      ViewingRequest,
      Match,
      WorkerProfile,
    ]),
  ],
  providers: [TrustService],
  exports: [TrustService],
})
export class TrustModule {}
