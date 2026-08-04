import { Module } from '@nestjs/common';
import { MatchesController } from './matches.controller';
import { TeamChallengesController } from './team-challenges.controller';
import { MatchesService } from './matches.service';
import { TeamChallengesService } from './team-challenges.service';

@Module({
  controllers: [MatchesController, TeamChallengesController],
  providers: [MatchesService, TeamChallengesService],
})
export class MatchesModule {}
