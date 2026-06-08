# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/ranking/ ./services/ranking/

WORKDIR /app/services/ranking
RUN npm ci --legacy-peer-deps
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/ranking

COPY --from=builder /app/services/ranking/dist ./dist
COPY --from=builder /app/services/ranking/package*.json ./
RUN npm ci --only=production --legacy-peer-deps

COPY --from=builder /app/services/ranking/drizzle ./drizzle
COPY --from=builder /app/services/ranking/scripts ./scripts
COPY --from=builder /app/services/ranking/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4009

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
