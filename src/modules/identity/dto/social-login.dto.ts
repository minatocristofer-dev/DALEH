import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class SocialLoginDto {
  // Access token de sessão emitido pelo Supabase Auth depois do OAuth (Google/Apple)
  @IsString()
  accessToken: string;

  // Só é exigido (e precisa ser true) quando é a primeira vez do usuário —
  // login social de quem já tem conta não deve re-pedir consentimento.
  @IsOptional()
  @IsBoolean()
  consentimentoDadosSensiveis?: boolean;
}
