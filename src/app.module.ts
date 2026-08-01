import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { IdentityModule } from './modules/identity/identity.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    IdentityModule,
    // Próximos módulos, na ordem do plano de implementação:
    // TeamsModule (times + convocação), VenuesModule (quadras + agenda),
    // MatchesModule (peladas + marketplace de adversário), NotificationsModule (push).
  ],
})
export class AppModule {}
