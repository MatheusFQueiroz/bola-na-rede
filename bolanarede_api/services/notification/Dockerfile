# syntax=docker/dockerfile:1
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/notification/package*.json ./services/notification/
COPY services/notification/tsconfig.json ./services/notification/
COPY services/notification/tsconfig.build.json ./services/notification/
COPY services/notification/nest-cli.json ./services/notification/
WORKDIR /app/services/notification
RUN --mount=type=cache,target=/root/.npm npm ci --legacy-peer-deps && \
    npm install -g @nestjs/cli@^11 --legacy-peer-deps

WORKDIR /app
COPY services/notification/src ./services/notification/src
WORKDIR /app/services/notification
RUN nest build

# ---- Runner ----
FROM node:22-alpine AS runner
RUN apk add --no-cache dumb-init

WORKDIR /app/services/notification

COPY --from=builder /app/services/notification/dist ./dist
COPY --from=builder /app/services/notification/package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --only=production --legacy-peer-deps

COPY services/notification/scripts ./scripts
COPY services/notification/docker-entrypoint.sh ./
RUN sed -i 's/\r//' docker-entrypoint.sh && chmod +x docker-entrypoint.sh

EXPOSE 4010

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
