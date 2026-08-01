import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Remove campos não esperados no DTO e valida automaticamente todo payload recebido
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  app.enableCors(); // ajustar origem permitida quando o app mobile/web tiver domínio definido
  app.setGlobalPrefix('v1');

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  console.log(`DALEH API rodando em http://localhost:${port}/v1`);
}
bootstrap();
