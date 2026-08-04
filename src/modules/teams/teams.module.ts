import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { TeamsController } from './teams.controller';
import { CallUpsController } from './call-ups.controller';
import { TeamsService } from './teams.service';

@Module({
  imports: [NotificationsModule],
  controllers: [TeamsController, CallUpsController],
  providers: [TeamsService],
})
export class TeamsModule {}
