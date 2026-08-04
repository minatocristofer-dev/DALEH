import { IsInt, IsNumber, IsString, Max, Min } from 'class-validator';

export class CreateSlotDto {
  // 0=Segunda ... 6=Domingo, seguindo a grade do protótipo visual
  @IsInt()
  @Min(0)
  @Max(6)
  weekday: number;

  @IsString()
  startTime: string;

  @IsString()
  endTime: string;

  @IsNumber()
  price: number;
}
