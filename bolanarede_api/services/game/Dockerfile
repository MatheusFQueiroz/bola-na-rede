# syntax=docker/dockerfile:1
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/game/package*.json ./services/game/
COPY services/game/tsconfig.json ./services/game/
COPY services/game/tsconfig.build.json ./services/game/
COPY services/game/nest-cli.json ./services/game/
WORKDIR /app/services/game
RUN --mount=type=cache,target=/root/.npm npm ci --legacy-peer-deps

WORKDIR /app
COPY services/game/src ./services/game/src
WORKDIR /app/services/game
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner
RUN apk add --no-cache dumb-init

WORKDIR /app/services/game

COPY --from=builder /app/services/game/dist ./dist
COPY --from=builder /app/services/game/package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --only=production --legacy-peer-deps

COPY services/game/drizzle ./drizzle
COPY services/game/scripts ./scripts
COPY services/game/docker-entrypoint.sh ./
RUN sed -i 's/\r//' docker-entrypoint.sh && chmod +x docker-entrypoint.sh

EXPOSE 4008

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
