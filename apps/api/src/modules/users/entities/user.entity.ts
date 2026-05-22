import { Column, Entity, OneToMany, OneToOne } from 'typeorm';
import { BaseEntity } from '../../../common/entities/base.entity';
import { UserRole } from '../../../common/enums/user-role.enum';
import { UserStatus } from '../../../common/enums/user-status.enum';
import { Property } from '../../properties/entities/property.entity';
import { WorkerProfile } from '../../workers/entities/worker-profile.entity';
import { TrustScore } from '../../trust/entities/trust-score.entity';

@Entity('users')
export class User extends BaseEntity {
  @Column({ type: 'varchar', length: 20, unique: true })
  phone: string;

  @Column({ type: 'enum', enum: UserRole })
  role: UserRole;

  @Column({ name: 'full_name', type: 'varchar', length: 255, nullable: true })
  fullName: string | null;

  @Column({ name: 'national_id_url', type: 'varchar', length: 512, nullable: true })
  nationalIdUrl: string | null;

  @Column({ name: 'verified_at', type: 'timestamptz', nullable: true })
  verifiedAt: Date | null;

  @Column({ type: 'enum', enum: UserStatus, default: UserStatus.PENDING })
  status: UserStatus;

  @OneToMany(() => Property, (property) => property.owner)
  properties: Property[];

  @OneToOne(() => WorkerProfile, (profile) => profile.user)
  workerProfile: WorkerProfile | null;

  @OneToOne(() => TrustScore, (trust) => trust.user)
  trustScore: TrustScore | null;
}
