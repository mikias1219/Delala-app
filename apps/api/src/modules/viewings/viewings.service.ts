import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PropertyStatus } from '../../common/enums/property-status.enum';
import { UserRole } from '../../common/enums/user-role.enum';
import { ViewingStatus } from '../../common/enums/viewing-status.enum';
import { ContactAccessService } from '../../common/services/contact-access.service';
import { NotificationsService } from '../notifications/notifications.service';
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
    private readonly notifications: NotificationsService,
    private readonly contactAccess: ContactAccessService,
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
    const saved = await this.viewingsRepo.save(viewing);

    await this.notifications.create(property.ownerId, 'viewing_requested', {
      viewingId: saved.id,
      propertyId,
      renterId,
    });

    return saved;
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
    const saved = await this.viewingsRepo.save(viewing);

    await this.notifications.create(viewing.renterId, 'viewing_scheduled', {
      viewingId: saved.id,
      propertyId: viewing.propertyId,
      scheduledAt: saved.scheduledAt,
    });

    return saved;
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

    const rows = await qb.getMany();
    const viewerRole =
      role === 'owner' ? UserRole.OWNER : UserRole.RENTER;

    return Promise.all(
      rows.map(async (v) => {
        const otherId =
          role === 'owner' ? v.renterId : v.property?.ownerId ?? '';
        const canContact =
          otherId &&
          (await this.contactAccess.canViewContact(
            userId,
            viewerRole,
            otherId,
          ));
        if (v.renter && !canContact && role === 'owner') {
          const { phone: _p, nationalIdUrl: _n, ...renterSafe } = v.renter;
          v.renter = renterSafe as typeof v.renter;
        }
        return v;
      }),
    );
  }
}
