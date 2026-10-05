import { IsNumber, IsString, Length, Min } from 'class-validator';

export class CriarCobrancaDto {
  @IsString()
  @Length(1, 80)
  titulo: string;

  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  valor: number;
}
