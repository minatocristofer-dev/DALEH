import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { VenuesController } from './venues.controller';
import { BookingsController } from './bookings.controller';
import { VenuesService } from './venues.service';

@Module({
  imports: [NotificationsModule],
  controllers: [VenuesController, BookingsController],
  providers: [VenuesService],
})
export class VenuesModule {}
