import { Controller, Get } from '@nestjs/common';

@Controller()
export class HealthController {
  @Get()
  status() {
    return { status: 'ok', service: 'daleh-api' };
  }
}
