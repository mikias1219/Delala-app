import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
} from 'typeorm';
import { BaseEntity } from '../../../common/entities/base.entity';
import { PropertyStatus } from '../../../common/enums/property-status.enum';
import { User } from '../../users/entities/user.entity';
import { PropertyPhoto } from './property-photo.entity';
import { ViewingRequest } from '../../viewings/entities/viewing-request.entity';

@Entity('properties')
export class Property extends BaseEntity {
  @Column({ name: 'owner_id' })
  ownerId: string;

  @ManyToOne(() => User, (user) => user.properties)
  @JoinColumn({ name: 'owner_id' })
  owner: User;

  @Column()
  title: string;

  @Column({ type: 'text' })
  description: string;

  @Column({ name: 'price_etb', type: 'decimal', precision: 12, scale: 2 })
  priceEtb: string;

  @Column({ type: 'int' })
  bedrooms: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  lat: string | null;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  lng: string | null;

  @Column({ type: 'enum', enum: PropertyStatus, default: PropertyStatus.DRAFT })
  status: PropertyStatus;

  @Column({ name: 'verified_at', type: 'timestamptz', nullable: true })
  verifiedAt: Date | null;

  @OneToMany(() => PropertyPhoto, (photo) => photo.property)
  photos: PropertyPhoto[];

  @OneToMany(() => ViewingRequest, (viewing) => viewing.property)
  viewings: ViewingRequest[];
}
