import { IsEnum, IsOptional, IsString, Length, Matches } from 'class-validator';
import { UserRole } from '../../../common/enums/user-role.enum';

export class VerifyOtpDto {
  @IsString()
  @Matches(/^\+2519\d{8}$|^09\d{8}$/)
  phone: string;

  @IsString()
  @Length(6, 6)
  code: string;

  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;
}
