# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/team/ ./services/team/

WORKDIR /app/services/team
RUN npm ci --legacy-peer-deps
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/team

COPY --from=builder /app/services/team/dist ./dist
COPY --from=builder /app/services/team/package*.json ./
RUN npm ci --only=production --legacy-peer-deps

COPY --from=builder /app/services/team/drizzle ./drizzle
COPY services/team/scripts ./scripts
COPY services/team/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4002

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
