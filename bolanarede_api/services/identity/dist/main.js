"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const bootstrap_http_app_1 = require("@shared/infra/http/bootstrap-http-app");
const app_module_1 = require("./app.module");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule);
    await (0, bootstrap_http_app_1.bootstrapHttpApp)(app);
}
bootstrap();
