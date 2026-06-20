# syntax=docker/dockerfile:1
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/matchmaking/package*.json ./services/matchmaking/
COPY services/matchmaking/tsconfig.json ./services/matchmaking/
COPY services/matchmaking/tsconfig.build.json ./services/matchmaking/
COPY services/matchmaking/nest-cli.json ./services/matchmaking/
WORKDIR /app/services/matchmaking
RUN --mount=type=cache,target=/root/.npm npm ci --legacy-peer-deps

WORKDIR /app
COPY services/matchmaking/src ./services/matchmaking/src
WORKDIR /app/services/matchmaking
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner
RUN apk add --no-cache dumb-init

WORKDIR /app/services/matchmaking

COPY --from=builder /app/services/matchmaking/dist ./dist
COPY --from=builder /app/services/matchmaking/package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --only=production --legacy-peer-deps

COPY services/matchmaking/drizzle ./drizzle
COPY services/matchmaking/scripts ./scripts
COPY services/matchmaking/docker-entrypoint.sh ./
RUN sed -i 's/\r//' docker-entrypoint.sh && chmod +x docker-entrypoint.sh

EXPOSE 4007

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
