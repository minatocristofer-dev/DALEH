import { IsIn } from 'class-validator';

export class UpdateBookingStatusDto {
  @IsIn(['confirmed', 'cancelled'])
  status: 'confirmed' | 'cancelled';
}
