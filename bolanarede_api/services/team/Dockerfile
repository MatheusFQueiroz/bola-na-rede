# syntax=docker/dockerfile:1
# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/team/package*.json ./services/team/
COPY services/team/tsconfig.json ./services/team/
COPY services/team/tsconfig.build.json ./services/team/
COPY services/team/nest-cli.json ./services/team/
WORKDIR /app/services/team
RUN --mount=type=cache,target=/root/.npm npm ci --legacy-peer-deps

WORKDIR /app
COPY services/team/src ./services/team/src
WORKDIR /app/services/team
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner
RUN apk add --no-cache dumb-init

WORKDIR /app/services/team

COPY --from=builder /app/services/team/dist ./dist
COPY --from=builder /app/services/team/package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --only=production --legacy-peer-deps

COPY services/team/drizzle ./drizzle
COPY services/team/scripts ./scripts
COPY services/team/docker-entrypoint.sh ./
RUN sed -i 's/\r//' docker-entrypoint.sh && chmod +x docker-entrypoint.sh

EXPOSE 4002

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
