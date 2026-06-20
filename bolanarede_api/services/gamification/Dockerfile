# syntax=docker/dockerfile:1
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/gamification/package*.json ./services/gamification/
COPY services/gamification/tsconfig.json ./services/gamification/
COPY services/gamification/tsconfig.build.json ./services/gamification/
COPY services/gamification/nest-cli.json ./services/gamification/
WORKDIR /app/services/gamification
RUN --mount=type=cache,target=/root/.npm npm ci --legacy-peer-deps

WORKDIR /app
COPY services/gamification/src ./services/gamification/src
WORKDIR /app/services/gamification
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner
RUN apk add --no-cache dumb-init

WORKDIR /app/services/gamification

COPY --from=builder /app/services/gamification/dist ./dist
COPY --from=builder /app/services/gamification/package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --only=production --legacy-peer-deps

COPY services/gamification/drizzle ./drizzle
COPY services/gamification/scripts ./scripts
COPY services/gamification/docker-entrypoint.sh ./
RUN sed -i 's/\r//' docker-entrypoint.sh && chmod +x docker-entrypoint.sh

EXPOSE 4006

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
