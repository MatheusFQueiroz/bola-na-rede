# syntax=docker/dockerfile:1
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/field/package*.json ./services/field/
COPY services/field/tsconfig.json ./services/field/
COPY services/field/tsconfig.build.json ./services/field/
COPY services/field/nest-cli.json ./services/field/
WORKDIR /app/services/field
RUN --mount=type=cache,target=/root/.npm npm ci --legacy-peer-deps

WORKDIR /app
COPY services/field/src ./services/field/src
WORKDIR /app/services/field
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner
RUN apk add --no-cache dumb-init

WORKDIR /app/services/field

COPY --from=builder /app/services/field/dist ./dist
COPY --from=builder /app/services/field/package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --only=production --legacy-peer-deps

COPY services/field/drizzle ./drizzle
COPY services/field/scripts ./scripts
COPY services/field/docker-entrypoint.sh ./
RUN sed -i 's/\r//' docker-entrypoint.sh && chmod +x docker-entrypoint.sh

EXPOSE 4003

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
