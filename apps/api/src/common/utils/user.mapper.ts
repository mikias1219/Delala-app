import { User } from '../../modules/users/entities/user.entity';

export type PublicUser = {
  id: string;
  phone?: string;
  role: string;
  fullName: string | null;
  status: string;
  verifiedAt: Date | null;
  createdAt: Date;
};

export function toPublicUser(user: User, includePhone = false): PublicUser {
  const base: PublicUser = {
    id: user.id,
    role: user.role,
    fullName: user.fullName,
    status: user.status,
    verifiedAt: user.verifiedAt,
    createdAt: user.createdAt,
  };
  if (includePhone) {
    base.phone = user.phone;
  }
  return base;
}
