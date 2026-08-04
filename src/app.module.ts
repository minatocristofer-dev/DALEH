import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { IdentityModule } from './modules/identity/identity.module';
import { TeamsModule } from './modules/teams/teams.module';
import { VenuesModule } from './modules/venues/venues.module';
import { HealthController } from './health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    IdentityModule,
    TeamsModule,
    VenuesModule,
    // Próximos módulos, na ordem do plano de implementação:
    // MatchesModule (peladas + marketplace de adversário),
    // NotificationsModule (push).
  ],
  controllers: [HealthController],
})
export class AppModule {}
