"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.bootstrapHttpApp = bootstrapHttpApp;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const core_1 = require("@nestjs/core");
const swagger_1 = require("@nestjs/swagger");
const hateoas_interceptor_1 = require("../hateoas/hateoas.interceptor");
async function bootstrapHttpApp(app) {
    const logger = new common_1.Logger('Bootstrap');
    const config = app.get(config_1.ConfigService);
    const port = config.get('PORT', 3000);
    const reflector = app.get(core_1.Reflector);
    app.setGlobalPrefix('v1');
    app.enableCors({ origin: '*' });
    app.useGlobalPipes(new common_1.ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
    }));
    app.useGlobalInterceptors(new hateoas_interceptor_1.HateoasInterceptor(reflector));
    const swaggerConfig = new swagger_1.DocumentBuilder()
        .setTitle('BolaNaRede API')
        .setVersion('1.0')
        .addBearerAuth()
        .build();
    const document = swagger_1.SwaggerModule.createDocument(app, swaggerConfig);
    swagger_1.SwaggerModule.setup('docs', app, document);
    try {
        await app.listen(port);
        logger.log(`Service running on port ${port}`);
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        logger.error(`Failed to start service on port ${port}: ${message}`);
        throw error;
    }
}
