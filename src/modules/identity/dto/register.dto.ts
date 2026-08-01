import {
  IsArray,
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

class ModalidadeDto {
  @IsIn(['FUTSAL', 'SOCIETY', 'CAMPO11'])
  modalidade: 'FUTSAL' | 'SOCIETY' | 'CAMPO11';

  @IsString()
  posicaoPrincipal: string;

  @IsOptional()
  @IsString()
  posicaoSecundaria?: string;
}

// Reflete os 3 passos do cadastro que já validamos no protótipo:
// (1) dados básicos, (2) modalidades + posição, (3) foto/revisão.
export class RegisterDto {
  @IsString()
  @MinLength(2)
  fullName: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  state?: string;

  @IsOptional()
  @IsIn(['Direito', 'Esquerdo', 'Ambos'])
  dominantFoot?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ModalidadeDto)
  modalidades: ModalidadeDto[];

  // Consentimento LGPD explícito — obrigatório e separado do "aceite os termos" genérico,
  // conforme o cuidado apontado no plano de implementação (seção 2).
  @IsIn([true])
  consentimentoDadosSensiveis: boolean;
}
