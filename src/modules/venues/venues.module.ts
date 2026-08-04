import { Module } from '@nestjs/common';
import { VenuesController } from './venues.controller';
import { BookingsController } from './bookings.controller';
import { VenuesService } from './venues.service';

@Module({
  controllers: [VenuesController, BookingsController],
  providers: [VenuesService],
})
export class VenuesModule {}
