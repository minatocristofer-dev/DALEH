import { IsIn, IsString } from 'class-validator';

export class RegisterDeviceTokenDto {
  @IsString()
  token: string;

  @IsIn(['web', 'android', 'ios'])
  platform: 'web' | 'android' | 'ios';
}
