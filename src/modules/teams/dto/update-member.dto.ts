import { IsIn } from 'class-validator';

export class UpdateMemberDto {
  @IsIn(['JOGADOR', 'CAPITAO', 'VICE_CAPITAO', 'TESOUREIRO'])
  papel: 'JOGADOR' | 'CAPITAO' | 'VICE_CAPITAO' | 'TESOUREIRO';
}
