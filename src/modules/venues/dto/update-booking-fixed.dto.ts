import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateBookingFixedDto {
  @IsBoolean()
  isFixed: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  fixedTeamName?: string;
}
