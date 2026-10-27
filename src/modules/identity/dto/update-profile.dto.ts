import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(30)
  nickname?: string;

  @IsOptional()
  @IsIn(['Direito', 'Esquerdo', 'Ambos'])
  dominantFoot?: string;
}

export class UpdatePositionDto {
  @IsIn(['FUTSAL', 'SOCIETY', 'CAMPO11'])
  modalidade: 'FUTSAL' | 'SOCIETY' | 'CAMPO11';

  @IsString()
  posicaoPrincipal: string;

  @IsOptional()
  @IsString()
  posicaoSecundaria?: string;
}
