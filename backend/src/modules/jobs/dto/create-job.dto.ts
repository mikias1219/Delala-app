import { IsNumber, IsOptional, IsString, Min, MinLength } from 'class-validator';

export class CreateJobDto {
  @IsString()
  @MinLength(2)
  jobType: string;

  @IsString()
  @MinLength(2)
  location: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  salaryOffer?: number;

  @IsOptional()
  @IsString()
  requirements?: string;
}
