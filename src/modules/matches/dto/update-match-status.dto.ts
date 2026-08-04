import { IsIn } from 'class-validator';

export class UpdateMatchStatusDto {
  @IsIn(['scheduled', 'in_progress', 'finished', 'cancelled'])
  status: 'scheduled' | 'in_progress' | 'finished' | 'cancelled';
}
