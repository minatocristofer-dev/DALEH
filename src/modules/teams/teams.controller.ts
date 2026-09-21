import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser, UsuarioAutenticado } from '../../common/decorators/current-user.decorator';
import { SupabaseStorageService } from '../../common/storage/supabase-storage.service';
import { TeamsService } from './teams.service';
import { CreateTeamDto } from './dto/create-team.dto';
import { AddMemberDto } from './dto/add-member.dto';
import { UpdateMemberDto } from './dto/update-member.dto';
import { CreateCallUpDto } from './dto/create-call-up.dto';

const TIPOS_DE_IMAGEM_ACEITOS = ['image/png', 'image/jpeg'];
const TAMANHO_MAXIMO_BYTES = 8 * 1024 * 1024;

@Controller('teams')
@UseGuards(AuthGuard('jwt'))
export class TeamsController {
  constructor(
    private teamsService: TeamsService,
    private storage: SupabaseStorageService,
  ) {}

  @Post()
  criar(@CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateTeamDto) {
    return this.teamsService.criarTime(user.id, dto);
  }

  @Get('mine')
  meusTimes(@CurrentUser() user: UsuarioAutenticado) {
    return this.teamsService.listarMeusTimes(user.id);
  }

  @Get(':id')
  detalhe(@Param('id') id: string) {
    return this.teamsService.obterTime(id);
  }

  // Só dono/capitão/vice-capitão pode trocar (checado dentro do service) —
  // o backend não faz nenhuma composição de imagem, só guarda o resultado
  // que o app mandar.
  @Post(':id/crest')
  @UseInterceptors(FileInterceptor('file'))
  async enviarEscudo(
    @Param('id') id: string,
    @UploadedFile() arquivo: Express.Multer.File | undefined,
    @CurrentUser() user: UsuarioAutenticado,
  ) {
    if (!arquivo) {
      throw new BadRequestException('Nenhum arquivo enviado.');
    }
    if (!TIPOS_DE_IMAGEM_ACEITOS.includes(arquivo.mimetype)) {
      throw new BadRequestException('O escudo precisa ser PNG ou JPEG.');
    }
    if (arquivo.size > TAMANHO_MAXIMO_BYTES) {
      throw new BadRequestException('O escudo é grande demais (máximo 8MB).');
    }

    const crestUrl = await this.storage.enviarImagem('crests', `${id}.png`, arquivo.buffer, arquivo.mimetype);
    return this.teamsService.atualizarEscudo(id, user.id, crestUrl);
  }

  @Post(':id/members')
  adicionarMembro(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: AddMemberDto) {
    return this.teamsService.adicionarMembro(id, user.id, dto);
  }

  @Patch(':id/members/:userId')
  atualizarMembro(
    @Param('id') id: string,
    @Param('userId') alvoUserId: string,
    @CurrentUser() user: UsuarioAutenticado,
    @Body() dto: UpdateMemberDto,
  ) {
    return this.teamsService.atualizarMembro(id, alvoUserId, user.id, dto);
  }

  @Delete(':id/members/:userId')
  removerMembro(@Param('id') id: string, @Param('userId') alvoUserId: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.teamsService.removerMembro(id, alvoUserId, user.id);
  }

  @Post(':id/call-ups')
  convocar(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateCallUpDto) {
    return this.teamsService.convocar(id, user.id, dto);
  }

  @Get(':id/call-ups')
  convocacoesDoTime(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.teamsService.listarConvocacoesDoTime(id, user.id);
  }
}
