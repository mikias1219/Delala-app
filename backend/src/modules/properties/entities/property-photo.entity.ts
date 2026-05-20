import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../../../common/entities/base.entity';
import { Property } from './property.entity';

@Entity('property_photos')
export class PropertyPhoto extends BaseEntity {
  @Column({ name: 'property_id' })
  propertyId: string;

  @ManyToOne(() => Property, (property) => property.photos, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'property_id' })
  property: Property;

  @Column()
  url: string;

  @Column({ name: 'is_primary', default: false })
  isPrimary: boolean;
}
