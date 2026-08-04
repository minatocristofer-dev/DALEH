import { IsBoolean, IsNumber, IsOptional, IsString, MinLength } from 'class-validator';

export class UpdateVenueDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  name?: string;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsNumber()
  lat?: number;

  @IsOptional()
  @IsNumber()
  lng?: number;

  @IsOptional()
  @IsBoolean()
  covered?: boolean;

  @IsOptional()
  @IsBoolean()
  hasParking?: boolean;

  @IsOptional()
  @IsBoolean()
  hasBar?: boolean;

  @IsOptional()
  @IsBoolean()
  hasLockerRoom?: boolean;

  @IsOptional()
  @IsBoolean()
  rentsVests?: boolean;

  @IsOptional()
  @IsBoolean()
  rentsBalls?: boolean;

  @IsOptional()
  @IsNumber()
  pricePerHour?: number;
}
