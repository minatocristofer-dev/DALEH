import { IsISO8601 } from 'class-validator';

export class CreateBookingDto {
  @IsISO8601()
  date: string;
}
