"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HateoasItem = void 0;
const common_1 = require("@nestjs/common");
const hateoas_types_1 = require("./hateoas.types");
const HateoasItem = (config) => (0, common_1.SetMetadata)(hateoas_types_1.HATEOAS_ITEM_KEY, config);
exports.HateoasItem = HateoasItem;
