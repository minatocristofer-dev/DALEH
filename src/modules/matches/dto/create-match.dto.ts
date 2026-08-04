import { IsIn, IsISO8601, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class CreateMatchDto {
  @IsIn(['FUTSAL', 'SOCIETY', 'CAMPO11'])
  modalidade: 'FUTSAL' | 'SOCIETY' | 'CAMPO11';

  @IsOptional()
  @IsString()
  venueId?: string;

  @IsISO8601()
  scheduledAt: string;

  @IsOptional()
  @IsInt()
  @Min(2)
  maxPlayers?: number;

  @IsOptional()
  @IsIn(['public', 'private'])
  visibility?: 'public' | 'private';
}
