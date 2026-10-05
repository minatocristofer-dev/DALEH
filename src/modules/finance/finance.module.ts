import { Module } from '@nestjs/common';
import { AuthorizationModule } from '../../common/authorization/authorization.module';
import { FinanceController } from './finance.controller';
import { FinanceService } from './finance.service';

@Module({
  imports: [AuthorizationModule],
  controllers: [FinanceController],
  providers: [FinanceService],
})
export class FinanceModule {}
