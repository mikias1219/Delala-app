import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../common/entities/base.entity';
import { ViewingStatus } from '../../../common/enums/viewing-status.enum';
import { Property } from '../../properties/entities/property.entity';
import { User } from '../../users/entities/user.entity';

@Entity('viewing_requests')
export class ViewingRequest extends BaseEntity {
  @Column({ name: 'property_id' })
  propertyId: string;

  @ManyToOne(() => Property, (property) => property.viewings)
  @JoinColumn({ name: 'property_id' })
  property: Property;

  @Column({ name: 'renter_id' })
  renterId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'renter_id' })
  renter: User;

  @Column({ name: 'requested_at', type: 'timestamptz' })
  requestedAt: Date;

  @Column({ name: 'scheduled_at', type: 'timestamptz', nullable: true })
  scheduledAt: Date | null;

  @Column({ type: 'enum', enum: ViewingStatus, default: ViewingStatus.REQUESTED })
  status: ViewingStatus;

  @Column({ type: 'text', nullable: true })
  notes: string | null;
}
