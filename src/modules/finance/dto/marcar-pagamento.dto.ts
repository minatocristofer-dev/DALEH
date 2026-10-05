import { IsBoolean } from 'class-validator';

export class MarcarPagamentoDto {
  @IsBoolean()
  pago: boolean;
}
