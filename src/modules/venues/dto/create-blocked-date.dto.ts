import { IsDateString, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateBlockedDateDto {
  @IsDateString()
  date: string;

  @IsOptional()
  @IsString()
  @MaxLength(140)
  reason?: string;
}
