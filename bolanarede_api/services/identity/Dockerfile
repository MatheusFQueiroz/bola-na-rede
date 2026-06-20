# syntax=docker/dockerfile:1
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/identity/package*.json ./services/identity/
COPY services/identity/tsconfig.json ./services/identity/
COPY services/identity/tsconfig.build.json ./services/identity/
COPY services/identity/nest-cli.json ./services/identity/
WORKDIR /app/services/identity
RUN --mount=type=cache,target=/root/.npm npm ci --legacy-peer-deps

WORKDIR /app
COPY services/identity/src ./services/identity/src
WORKDIR /app/services/identity
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner
RUN apk add --no-cache dumb-init

WORKDIR /app/services/identity

COPY --from=builder /app/services/identity/dist ./dist
COPY --from=builder /app/services/identity/package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --only=production --legacy-peer-deps

COPY services/identity/drizzle ./drizzle
COPY services/identity/scripts ./scripts
COPY services/identity/docker-entrypoint.sh ./
RUN sed -i 's/\r//' docker-entrypoint.sh && chmod +x docker-entrypoint.sh

EXPOSE 4001

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
