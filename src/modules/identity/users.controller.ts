import {
  BadRequestException,
  Controller,
  Get,
  Param,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser, UsuarioAutenticado } from '../../common/decorators/current-user.decorator';
import { AuthService } from './auth.service';
import { SupabaseStorageService } from './supabase-storage.service';

const TIPOS_ACEITOS = ['image/png', 'image/jpeg'];
const TAMANHO_MAXIMO_BYTES = 8 * 1024 * 1024; // 8MB — suficiente pra foto composta com a camisa, sem abrir espaço pra abuso.

// Perfil público (Fase 7) — separado de `AuthController` (que é só ações de
// autenticação) porque `/users/:id` é um recurso, não uma ação de auth.
// Qualquer usuário autenticado pode ver o perfil de qualquer outro (decisão
// explícita desta fase — não exige time/jogo em comum, não tem sistema de
// privacidade além de nunca devolver e-mail/telefone/data de nascimento).
@Controller('users')
@UseGuards(AuthGuard('jwt'))
export class UsersController {
  constructor(
    private authService: AuthService,
    private storage: SupabaseStorageService,
  ) {}

  @Get(':id')
  perfilPublico(@Param('id') id: string) {
    return this.authService.perfilPublico(id);
  }

  // POST /v1/users/me/avatar — recebe a imagem já composta (rosto do
  // jogador encaixado na camisa do DALEH), montada no app. O backend não
  // faz nenhuma composição de imagem, só guarda o resultado final.
  @Post('me/avatar')
  @UseInterceptors(FileInterceptor('file'))
  async enviarAvatar(@UploadedFile() arquivo: Express.Multer.File | undefined, @CurrentUser() user: UsuarioAutenticado) {
    if (!arquivo) {
      throw new BadRequestException('Nenhum arquivo enviado.');
    }
    if (!TIPOS_ACEITOS.includes(arquivo.mimetype)) {
      throw new BadRequestException('A foto precisa ser PNG ou JPEG.');
    }
    if (arquivo.size > TAMANHO_MAXIMO_BYTES) {
      throw new BadRequestException('A foto é grande demais (máximo 8MB).');
    }

    const avatarUrl = await this.storage.enviarAvatar(user.id, arquivo.buffer, arquivo.mimetype);
    return this.authService.atualizarAvatar(user.id, avatarUrl);
  }
}
