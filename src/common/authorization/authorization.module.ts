import { Module } from '@nestjs/common';
import { TeamAuthorizationService } from './team-authorization.service';

@Module({
  providers: [TeamAuthorizationService],
  exports: [TeamAuthorizationService],
})
export class AuthorizationModule {}
