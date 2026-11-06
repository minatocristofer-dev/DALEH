import { IsIn, IsISO8601, IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreateMatchDto {
  @IsIn(['FUTSAL', 'SOCIETY', 'CAMPO11'])
  modalidade: 'FUTSAL' | 'SOCIETY' | 'CAMPO11';

  @IsOptional()
  @IsString()
  venueId?: string;

  // Nome digitado livre pro local, pra quando o jogo é numa quadra sem
  // dono cadastrado no DALEH ainda (ver comentário no schema). Ignorado
  // se `venueId` também vier — a Venue real sempre prevalece.
  @IsOptional()
  @IsString()
  @MaxLength(120)
  locationName?: string;

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
