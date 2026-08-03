import { IsISO8601, IsOptional, IsString } from 'class-validator';

export class CreateCallUpDto {
  @IsString()
  venueNameSnapshot: string;

  @IsISO8601()
  scheduledDate: string;

  @IsString()
  scheduledTime: string;

  @IsOptional()
  @IsString()
  matchId?: string;
}
