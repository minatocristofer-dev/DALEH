import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

// @Global() faz o PrismaService ficar disponível em qualquer módulo
// sem precisar importar PrismaModule toda vez.
@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
