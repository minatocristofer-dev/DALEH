import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { IdentityModule } from './modules/identity/identity.module';
import { TeamsModule } from './modules/teams/teams.module';
import { HealthController } from './health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    IdentityModule,
    TeamsModule,
    // Próximos módulos, na ordem do plano de implementação:
    // VenuesModule (quadras + agenda), MatchesModule (peladas + marketplace
    // de adversário), NotificationsModule (push).
  ],
  controllers: [HealthController],
})
export class AppModule {}
