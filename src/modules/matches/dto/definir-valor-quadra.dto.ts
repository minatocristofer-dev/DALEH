import { IsNumber, Max, Min, ValidateIf } from 'class-validator';

export class DefinirValorQuadraDto {
  @ValidateIf((o) => o.valor !== null)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  @Max(100000)
  valor: number | null;
}
