"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createRabbitMQConfig = createRabbitMQConfig;
function createRabbitMQConfig(config) {
    return {
        exchanges: [
            { name: 'bolanarededb', type: 'topic' },
            { name: 'bolanarededb.dlq', type: 'topic' },
        ],
        uri: config.getOrThrow('RABBITMQ_URL'),
        connectionInitOptions: { wait: false },
    };
}
