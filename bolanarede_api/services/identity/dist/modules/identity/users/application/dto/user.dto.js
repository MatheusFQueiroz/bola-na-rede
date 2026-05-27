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
exports.UserDto = void 0;
const swagger_1 = require("@nestjs/swagger");
class UserDto {
    static fromUserAndProfile(user, profile) {
        const dto = new UserDto();
        dto.id = user.id;
        dto.email = user.email;
        dto.createdAt = user.createdAt;
        if (profile) {
            dto.displayName = profile.displayName;
            dto.photoUrl = profile.photoUrl;
            dto.bio = profile.bio;
            dto.city = profile.city;
            dto.position = profile.position;
            dto.skillLevel = profile.skillLevel;
            dto.isPublic = profile.isPublic;
        }
        return dto;
    }
}
exports.UserDto = UserDto;
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'ID público do usuário (UUID)' }),
    __metadata("design:type", String)
], UserDto.prototype, "id", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: 'Email' }),
    __metadata("design:type", Object)
], UserDto.prototype, "email", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: 'Nome de exibição' }),
    __metadata("design:type", String)
], UserDto.prototype, "displayName", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: 'URL da foto' }),
    __metadata("design:type", Object)
], UserDto.prototype, "photoUrl", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: 'Bio' }),
    __metadata("design:type", Object)
], UserDto.prototype, "bio", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: 'Cidade' }),
    __metadata("design:type", Object)
], UserDto.prototype, "city", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: 'Posição' }),
    __metadata("design:type", Object)
], UserDto.prototype, "position", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: 'Nível de habilidade (1–5)' }),
    __metadata("design:type", Object)
], UserDto.prototype, "skillLevel", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: 'Perfil público?' }),
    __metadata("design:type", Boolean)
], UserDto.prototype, "isPublic", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Data de criação da conta' }),
    __metadata("design:type", Date)
], UserDto.prototype, "createdAt", void 0);
