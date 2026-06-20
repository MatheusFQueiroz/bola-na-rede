# syntax=docker/dockerfile:1
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/ranking/package*.json ./services/ranking/
COPY services/ranking/tsconfig.json ./services/ranking/
COPY services/ranking/tsconfig.build.json ./services/ranking/
COPY services/ranking/nest-cli.json ./services/ranking/
WORKDIR /app/services/ranking
RUN --mount=type=cache,target=/root/.npm npm ci --legacy-peer-deps

WORKDIR /app
COPY services/ranking/src ./services/ranking/src
WORKDIR /app/services/ranking
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner
RUN apk add --no-cache dumb-init

WORKDIR /app/services/ranking

COPY --from=builder /app/services/ranking/dist ./dist
COPY --from=builder /app/services/ranking/package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --only=production --legacy-peer-deps

COPY services/ranking/drizzle ./drizzle
COPY services/ranking/scripts ./scripts
COPY services/ranking/docker-entrypoint.sh ./
RUN sed -i 's/\r//' docker-entrypoint.sh && chmod +x docker-entrypoint.sh

EXPOSE 4009

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
