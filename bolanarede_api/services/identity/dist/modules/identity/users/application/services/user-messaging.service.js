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
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserMessagingService = void 0;
const common_1 = require("@nestjs/common");
const shared_messaging_service_1 = require("@shared/infra/messaging/shared-messaging.service");
const identity_events_enum_1 = require("@shared/contracts/events/identity-events.enum");
let UserMessagingService = class UserMessagingService {
    constructor(messaging) {
        this.messaging = messaging;
    }
    async publishUserRegistered(user) {
        await this.messaging.publish(identity_events_enum_1.IdentityEvents.USER_REGISTERED, {
            userId: user.id,
            email: user.email,
            createdAt: user.createdAt,
        });
    }
    async publishProfileUpdated(user, profile) {
        await this.messaging.publish(identity_events_enum_1.IdentityEvents.PROFILE_UPDATED, {
            userId: user.id,
            displayName: profile.displayName,
            photoUrl: profile.photoUrl,
            city: profile.city,
            position: profile.position,
        });
    }
    async publishDeviceTokenUpdated(userId, token, platform) {
        await this.messaging.publish(identity_events_enum_1.IdentityEvents.DEVICE_TOKEN_UPDATED, {
            userId,
            token,
            platform,
        });
    }
};
exports.UserMessagingService = UserMessagingService;
exports.UserMessagingService = UserMessagingService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof shared_messaging_service_1.SharedMessagingService !== "undefined" && shared_messaging_service_1.SharedMessagingService) === "function" ? _a : Object])
], UserMessagingService);
