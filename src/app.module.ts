import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { IdentityModule } from './modules/identity/identity.module';
import { TeamsModule } from './modules/teams/teams.module';
import { VenuesModule } from './modules/venues/venues.module';
import { MatchesModule } from './modules/matches/matches.module';
import { HealthController } from './health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    IdentityModule,
    TeamsModule,
    VenuesModule,
    MatchesModule,
    // Próximo módulo do plano de implementação: NotificationsModule (push real).
  ],
  controllers: [HealthController],
})
export class AppModule {}
