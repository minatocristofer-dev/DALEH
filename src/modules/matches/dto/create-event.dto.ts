import { IsIn, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class CreateEventDto {
  @IsString()
  userId: string;

  @IsIn(['goal', 'assist', 'yellow', 'red', 'mvp'])
  eventType: 'goal' | 'assist' | 'yellow' | 'red' | 'mvp';

  @IsOptional()
  @IsInt()
  @Min(0)
  minute?: number;
}
