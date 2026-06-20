# syntax=docker/dockerfile:1
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/social/package*.json ./services/social/
COPY services/social/tsconfig.json ./services/social/
COPY services/social/tsconfig.build.json ./services/social/
COPY services/social/nest-cli.json ./services/social/
WORKDIR /app/services/social
RUN --mount=type=cache,target=/root/.npm npm ci --legacy-peer-deps

WORKDIR /app
COPY services/social/src ./services/social/src
WORKDIR /app/services/social
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner
RUN apk add --no-cache dumb-init

WORKDIR /app/services/social

COPY --from=builder /app/services/social/dist ./dist
COPY --from=builder /app/services/social/package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --only=production --legacy-peer-deps

COPY services/social/drizzle ./drizzle
COPY services/social/scripts ./scripts
COPY services/social/docker-entrypoint.sh ./
RUN sed -i 's/\r//' docker-entrypoint.sh && chmod +x docker-entrypoint.sh

EXPOSE 4005

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
