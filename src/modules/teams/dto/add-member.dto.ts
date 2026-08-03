import { IsEmail, IsOptional, IsString } from 'class-validator';

// Aceita userId direto ou email (busca o usuário já cadastrado) — ainda não
// existe fluxo de convite por link/SMS pra quem não tem conta.
export class AddMemberDto {
  @IsOptional()
  @IsString()
  userId?: string;

  @IsOptional()
  @IsEmail()
  email?: string;
}
