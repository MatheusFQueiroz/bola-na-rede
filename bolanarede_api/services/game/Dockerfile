# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/game/ ./services/game/

WORKDIR /app/services/game
RUN npm ci --legacy-peer-deps
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/game

COPY --from=builder /app/services/game/dist ./dist
COPY --from=builder /app/services/game/package*.json ./
RUN npm ci --only=production --legacy-peer-deps

COPY --from=builder /app/services/game/drizzle ./drizzle
COPY --from=builder /app/services/game/scripts ./scripts
COPY --from=builder /app/services/game/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4008

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
