import { IsIn } from 'class-validator';

export class RespondCallUpDto {
  @IsIn(['CONFIRMADO', 'RECUSADO'])
  status: 'CONFIRMADO' | 'RECUSADO';
}
