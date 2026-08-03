import { Module } from '@nestjs/common';
import { TeamsController } from './teams.controller';
import { CallUpsController } from './call-ups.controller';
import { TeamsService } from './teams.service';

@Module({
  controllers: [TeamsController, CallUpsController],
  providers: [TeamsService],
})
export class TeamsModule {}
