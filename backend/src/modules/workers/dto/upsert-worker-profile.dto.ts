import {
  IsArray,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  MinLength,
} from 'class-validator';

export class UpsertWorkerProfileDto {
  @IsArray()
  @IsString({ each: true })
  skills: string[];

  @IsOptional()
  @IsString()
  availability?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  salaryExpectation?: number;

  @IsOptional()
  @IsString()
  @MinLength(10)
  bio?: string;
}
