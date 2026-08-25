import { Module } from '@nestjs/common';
import { AuthorizationModule } from '../../common/authorization/authorization.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { MatchesController } from './matches.controller';
import { TeamChallengesController } from './team-challenges.controller';
import { MatchesService } from './matches.service';
import { TeamChallengesService } from './team-challenges.service';

@Module({
  imports: [AuthorizationModule, NotificationsModule],
  controllers: [MatchesController, TeamChallengesController],
  providers: [MatchesService, TeamChallengesService],
})
export class MatchesModule {}
