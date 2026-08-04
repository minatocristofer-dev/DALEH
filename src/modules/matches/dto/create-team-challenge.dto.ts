import { IsIn, IsISO8601, IsOptional, IsString } from 'class-validator';

export class CreateTeamChallengeDto {
  @IsString()
  teamId: string;

  @IsIn(['FUTSAL', 'SOCIETY', 'CAMPO11'])
  modalidade: 'FUTSAL' | 'SOCIETY' | 'CAMPO11';

  @IsString()
  city: string;

  @IsOptional()
  @IsString()
  venueId?: string;

  @IsISO8601()
  scheduledDate: string;

  @IsString()
  scheduledTime: string;

  @IsIn(['iniciante', 'intermediario', 'avancado'])
  desiredLevel: 'iniciante' | 'intermediario' | 'avancado';
}
