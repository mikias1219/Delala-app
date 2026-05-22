import { User } from '../../modules/users/entities/user.entity';

export type PublicUser = {
  id: string;
  phone: string;
  role: string;
  fullName: string | null;
  status: string;
  verifiedAt: Date | null;
  createdAt: Date;
};

export function toPublicUser(user: User): PublicUser {
  return {
    id: user.id,
    phone: user.phone,
    role: user.role,
    fullName: user.fullName,
    status: user.status,
    verifiedAt: user.verifiedAt,
    createdAt: user.createdAt,
  };
}
