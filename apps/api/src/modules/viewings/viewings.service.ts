import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PropertyStatus } from '../../common/enums/property-status.enum';
import { ViewingStatus } from '../../common/enums/viewing-status.enum';
import { Property } from '../properties/entities/property.entity';
import { ScheduleViewingDto } from './dto/schedule-viewing.dto';
import { ViewingRequest } from './entities/viewing-request.entity';

@Injectable()
export class ViewingsService {
  constructor(
    @InjectRepository(ViewingRequest)
    private readonly viewingsRepo: Repository<ViewingRequest>,
    @InjectRepository(Property)
    private readonly propertiesRepo: Repository<Property>,
  ) {}

  async createRequest(propertyId: string, renterId: string, notes?: string) {
    const property = await this.propertiesRepo.findOne({
      where: { id: propertyId },
    });
    if (!property) {
      throw new NotFoundException('Property not found');
    }
    if (property.status !== PropertyStatus.VERIFIED) {
      throw new BadRequestException('Property is not available for viewings');
    }
    if (property.ownerId === renterId) {
      throw new BadRequestException('Cannot request viewing on your own property');
    }

    const viewing = this.viewingsRepo.create({
      propertyId,
      renterId,
      requestedAt: new Date(),
      status: ViewingStatus.REQUESTED,
      notes: notes ?? null,
    });
    return this.viewingsRepo.save(viewing);
  }

  async schedule(
    viewingId: string,
    ownerId: string,
    dto: ScheduleViewingDto,
  ) {
    const viewing = await this.viewingsRepo.findOne({
      where: { id: viewingId },
      relations: ['property'],
    });
    if (!viewing) {
      throw new NotFoundException('Viewing request not found');
    }
    if (viewing.property.ownerId !== ownerId) {
      throw new ForbiddenException();
    }
    if (viewing.status === ViewingStatus.CANCELLED) {
      throw new BadRequestException('Viewing was cancelled');
    }

    viewing.scheduledAt = new Date(dto.scheduledAt);
    viewing.status = ViewingStatus.SCHEDULED;
    if (dto.notes) {
      viewing.notes = dto.notes;
    }
    return this.viewingsRepo.save(viewing);
  }

  async listForUser(userId: string, role: string) {
    const qb = this.viewingsRepo
      .createQueryBuilder('v')
      .leftJoinAndSelect('v.property', 'property')
      .leftJoinAndSelect('v.renter', 'renter')
      .orderBy('v.requestedAt', 'DESC');

    if (role === 'owner') {
      qb.where('property.ownerId = :userId', { userId });
    } else {
      qb.where('v.renterId = :userId', { userId });
    }

    return qb.getMany();
  }
}
