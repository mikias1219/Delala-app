import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TrustScore } from './entities/trust-score.entity';
import { TrustService } from './trust.service';

@Module({
  imports: [TypeOrmModule.forFeature([TrustScore])],
  providers: [TrustService],
  exports: [TrustService],
})
export class TrustModule {}
