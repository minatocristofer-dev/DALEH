import { IsString } from 'class-validator';

export class ElectMvpDto {
  @IsString()
  userId: string;
}
