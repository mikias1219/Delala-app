import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JobPost } from '../modules/jobs/entities/job-post.entity';
import { Match } from '../modules/jobs/entities/match.entity';
import { Notification } from '../modules/notifications/entities/notification.entity';
import { PropertyPhoto } from '../modules/properties/entities/property-photo.entity';
import { Property } from '../modules/properties/entities/property.entity';
import { Review } from '../modules/reviews/entities/review.entity';
import { TrustScore } from '../modules/trust/entities/trust-score.entity';
import { User } from '../modules/users/entities/user.entity';
import { ViewingRequest } from '../modules/viewings/entities/viewing-request.entity';
import { WorkerProfile } from '../modules/workers/entities/worker-profile.entity';

export const entities = [
  User,
  Property,
  PropertyPhoto,
  ViewingRequest,
  WorkerProfile,
  JobPost,
  Match,
  Review,
  TrustScore,
  Notification,
];

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get<string>('database.host'),
        port: config.get<number>('database.port'),
        username: config.get<string>('database.username'),
        password: config.get<string>('database.password'),
        database: config.get<string>('database.name'),
        entities,
        synchronize: config.get<string>('nodeEnv') !== 'production',
        logging: config.get<string>('nodeEnv') === 'development',
      }),
    }),
  ],
})
export class DatabaseModule {}
