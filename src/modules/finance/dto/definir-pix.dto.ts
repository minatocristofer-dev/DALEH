import { IsString, Length } from 'class-validator';

export class DefinirPixDto {
  @IsString()
  @Length(1, 100)
  pixKey: string;

  @IsString()
  @Length(1, 60)
  pixNome: string;
}
