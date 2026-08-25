import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class RegisterGoalDto {
  @IsString()
  scorerId: string;

  @IsOptional()
  @IsString()
  assistId?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  minute?: number;
}
