# syntax=docker/dockerfile:1
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/open-game/package*.json ./services/open-game/
COPY services/open-game/tsconfig.json ./services/open-game/
COPY services/open-game/tsconfig.build.json ./services/open-game/
COPY services/open-game/nest-cli.json ./services/open-game/
WORKDIR /app/services/open-game
RUN --mount=type=cache,target=/root/.npm npm ci --legacy-peer-deps

WORKDIR /app
COPY services/open-game/src ./services/open-game/src
WORKDIR /app/services/open-game
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner
RUN apk add --no-cache dumb-init

WORKDIR /app/services/open-game

COPY --from=builder /app/services/open-game/dist ./dist
COPY --from=builder /app/services/open-game/package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --only=production --legacy-peer-deps

COPY services/open-game/drizzle ./drizzle
COPY services/open-game/scripts ./scripts
COPY services/open-game/docker-entrypoint.sh ./
RUN sed -i 's/\r//' docker-entrypoint.sh && chmod +x docker-entrypoint.sh

EXPOSE 4004

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
