import { IsDateString, IsOptional, IsString, MaxLength } from 'class-validator';

export class ScheduleViewingDto {
  @IsDateString()
  scheduledAt: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
