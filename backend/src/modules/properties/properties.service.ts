import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PropertyStatus } from '../../common/enums/property-status.enum';
import { UserRole } from '../../common/enums/user-role.enum';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { CreatePropertyDto } from './dto/create-property.dto';
import { SearchPropertiesDto } from './dto/search-properties.dto';
import { Property } from './entities/property.entity';

@Injectable()
export class PropertiesService {
  constructor(
    @InjectRepository(Property)
    private readonly propertiesRepo: Repository<Property>,
  ) {}

  async search(query: SearchPropertiesDto) {
    const qb = this.propertiesRepo
      .createQueryBuilder('p')
      .leftJoinAndSelect('p.photos', 'photos')
      .where('p.status = :status', { status: PropertyStatus.VERIFIED });

    if (query.minPrice !== undefined) {
      qb.andWhere('p.price_etb >= :minPrice', { minPrice: query.minPrice });
    }
    if (query.maxPrice !== undefined) {
      qb.andWhere('p.price_etb <= :maxPrice', { maxPrice: query.maxPrice });
    }
    if (query.bedrooms !== undefined) {
      qb.andWhere('p.bedrooms = :bedrooms', { bedrooms: query.bedrooms });
    }

    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    qb.orderBy('p.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit);

    const [items, total] = await qb.getManyAndCount();
    return { items, total, page, limit };
  }

  async findById(id: string, publicOnly = true) {
    const property = await this.propertiesRepo.findOne({
      where: { id },
      relations: ['photos', 'owner'],
    });
    if (!property) {
      throw new NotFoundException('Property not found');
    }
    if (publicOnly && property.status !== PropertyStatus.VERIFIED) {
      throw new NotFoundException('Property not found');
    }
    return property;
  }

  async listByOwner(ownerId: string) {
    return this.propertiesRepo.find({
      where: { ownerId },
      relations: ['photos'],
      order: { createdAt: 'DESC' },
    });
  }

  async create(ownerId: string, dto: CreatePropertyDto) {
    const property = this.propertiesRepo.create({
      ownerId,
      title: dto.title,
      description: dto.description,
      priceEtb: String(dto.priceEtb),
      bedrooms: dto.bedrooms,
      lat: dto.lat != null ? String(dto.lat) : null,
      lng: dto.lng != null ? String(dto.lng) : null,
      status: PropertyStatus.PENDING_VERIFICATION,
    });
    return this.propertiesRepo.save(property);
  }

  async verify(propertyId: string) {
    const property = await this.propertiesRepo.findOne({ where: { id: propertyId } });
    if (!property) {
      throw new NotFoundException('Property not found');
    }
    property.status = PropertyStatus.VERIFIED;
    property.verifiedAt = new Date();
    return this.propertiesRepo.save(property);
  }

  assertOwnerOrAdmin(property: Property, user: JwtPayload) {
    if (user.role === UserRole.ADMIN) return;
    if (property.ownerId !== user.sub) {
      throw new ForbiddenException();
    }
  }
}
