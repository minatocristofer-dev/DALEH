import { Module } from '@nestjs/common';
import { AuthorizationModule } from '../../common/authorization/authorization.module';
import { StorageModule } from '../../common/storage/storage.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { TeamsController } from './teams.controller';
import { CallUpsController } from './call-ups.controller';
import { TeamsService } from './teams.service';

@Module({
  imports: [NotificationsModule, AuthorizationModule, StorageModule],
  controllers: [TeamsController, CallUpsController],
  providers: [TeamsService],
})
export class TeamsModule {}
