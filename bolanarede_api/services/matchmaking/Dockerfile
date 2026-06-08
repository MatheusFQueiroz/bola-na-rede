# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/matchmaking/ ./services/matchmaking/

WORKDIR /app/services/matchmaking
RUN npm ci --legacy-peer-deps
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/matchmaking

COPY --from=builder /app/services/matchmaking/dist ./dist
COPY --from=builder /app/services/matchmaking/package*.json ./
RUN npm ci --only=production --legacy-peer-deps

COPY --from=builder /app/services/matchmaking/drizzle ./drizzle
COPY --from=builder /app/services/matchmaking/scripts ./scripts
COPY --from=builder /app/services/matchmaking/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4007

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
