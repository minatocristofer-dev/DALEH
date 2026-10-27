import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateSupportTicketDto {
  @IsIn(['bug', 'sugestao', 'suporte', 'conta'])
  category: 'bug' | 'sugestao' | 'suporte' | 'conta';

  @IsString()
  @MaxLength(120)
  subject: string;

  @IsString()
  @MaxLength(2000)
  message: string;

  @IsOptional()
  @IsIn(['android', 'ios', 'web'])
  platform?: 'android' | 'ios' | 'web';

  @IsOptional()
  @IsString()
  @MaxLength(30)
  appVersion?: string;
}
