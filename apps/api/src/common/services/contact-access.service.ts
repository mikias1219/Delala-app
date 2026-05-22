import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MatchStatus } from '../enums/match-status.enum';
import { UserRole } from '../enums/user-role.enum';
import { ViewingStatus } from '../enums/viewing-status.enum';
import { Match } from '../../modules/jobs/entities/match.entity';
import { ViewingRequest } from '../../modules/viewings/entities/viewing-request.entity';

const CONFIRMED_VIEWING = [ViewingStatus.SCHEDULED, ViewingStatus.COMPLETED];
const CONFIRMED_MATCH = [MatchStatus.HIRED, MatchStatus.ENDED];

@Injectable()
export class ContactAccessService {
  constructor(
    @InjectRepository(ViewingRequest)
    private readonly viewingsRepo: Repository<ViewingRequest>,
    @InjectRepository(Match) private readonly matchesRepo: Repository<Match>,
  ) {}

  async canViewContact(
    viewerId: string,
    viewerRole: UserRole,
    targetUserId: string,
  ): Promise<boolean> {
    if (viewerId === targetUserId) return true;
    if (viewerRole === UserRole.ADMIN) return true;

    const viewingLink = await this.viewingsRepo
      .createQueryBuilder('v')
      .innerJoin('v.property', 'p')
      .where('v.status IN (:...statuses)', { statuses: CONFIRMED_VIEWING })
      .andWhere(
        '(v.renterId = :viewer AND p.ownerId = :target) OR (v.renterId = :target AND p.ownerId = :viewer)',
        { viewer: viewerId, target: targetUserId },
      )
      .getCount();

    if (viewingLink > 0) return true;

    const matchLink = await this.matchesRepo
      .createQueryBuilder('m')
      .innerJoin('m.jobPost', 'j')
      .innerJoin('m.worker', 'w')
      .where('m.status IN (:...statuses)', { statuses: CONFIRMED_MATCH })
      .andWhere(
        '(j.employerId = :viewer AND w.userId = :target) OR (j.employerId = :target AND w.userId = :viewer)',
        { viewer: viewerId, target: targetUserId },
      )
      .getCount();

    return matchLink > 0;
  }
}
