"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.HateoasInterceptor = void 0;
const common_1 = require("@nestjs/common");
const core_1 = require("@nestjs/core");
const operators_1 = require("rxjs/operators");
const hateoas_types_1 = require("./hateoas.types");
let HateoasInterceptor = class HateoasInterceptor {
    constructor(reflector) {
        this.reflector = reflector;
    }
    intercept(context, next) {
        const itemConfig = this.reflector.get(hateoas_types_1.HATEOAS_ITEM_KEY, context.getHandler());
        const listConfig = this.reflector.get(hateoas_types_1.HATEOAS_LIST_KEY, context.getHandler());
        if (!itemConfig && !listConfig)
            return next.handle();
        return next.handle().pipe((0, operators_1.map)((data) => {
            if (itemConfig) {
                return {
                    data,
                    _links: itemConfig.itemLinks(data),
                };
            }
            if (listConfig) {
                const items = Array.isArray(data) ? data : [];
                return {
                    data: items.map((item) => ({
                        ...item,
                        _links: listConfig.itemLinks(item),
                    })),
                    _links: {
                        self: { href: listConfig.basePath, method: 'GET' },
                        create: { href: listConfig.basePath, method: 'POST' },
                    },
                };
            }
            return data;
        }));
    }
};
exports.HateoasInterceptor = HateoasInterceptor;
exports.HateoasInterceptor = HateoasInterceptor = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [core_1.Reflector])
], HateoasInterceptor);
