"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HateoasList = void 0;
const common_1 = require("@nestjs/common");
const hateoas_types_1 = require("./hateoas.types");
const HateoasList = (config) => (0, common_1.SetMetadata)(hateoas_types_1.HATEOAS_LIST_KEY, config);
exports.HateoasList = HateoasList;
