import { IsEnum, IsOptional, IsString, Matches } from 'class-validator';
import { UserRole } from '../../../common/enums/user-role.enum';

export class RequestOtpDto {
  @IsString()
  @Matches(/^\+2519\d{8}$|^09\d{8}$/, {
    message: 'Phone must be Ethiopian format (+2519XXXXXXXX or 09XXXXXXXX)',
  })
  phone: string;

  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;
}
