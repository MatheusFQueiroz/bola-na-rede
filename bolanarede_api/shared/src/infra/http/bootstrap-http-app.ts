import { INestApplication, Logger, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { HateoasInterceptor } from '../hateoas/hateoas.interceptor';

export async function bootstrapHttpApp(app: INestApplication): Promise<void> {
  const logger = new Logger('Bootstrap');
  const config = app.get(ConfigService);
  const port = config.get<number>('PORT', 3000);
  const reflector = app.get(Reflector);

  app.setGlobalPrefix('v1');

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  app.useGlobalInterceptors(new HateoasInterceptor(reflector));

  const swaggerConfig = new DocumentBuilder()
    .setTitle('BolaNaRede API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('docs', app, document);

  try {
    await app.listen(port);
    logger.log(`Service running on port ${port}`);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error(`Failed to start service on port ${port}: ${message}`);
    throw error;
  }
}
