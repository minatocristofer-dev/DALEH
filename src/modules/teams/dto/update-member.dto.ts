import { IsIn, IsInt, IsOptional, Min } from 'class-validator';

export class UpdateMemberDto {
  @IsIn(['JOGADOR', 'CAPITAO', 'VICE_CAPITAO', 'TESOUREIRO'])
  papel: 'JOGADOR' | 'CAPITAO' | 'VICE_CAPITAO' | 'TESOUREIRO';

  // Quem escolhe é o administrador/capitão, não o próprio jogador — mesma
  // permissão já exigida pro resto deste endpoint. Omitido = não mexe no
  // número atual; `null` = limpa (remove o número); um inteiro = define.
  @IsOptional()
  @IsInt()
  @Min(0)
  numeroCamisa?: number | null;
}
