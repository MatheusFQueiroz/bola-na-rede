# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/gamification/ ./services/gamification/

WORKDIR /app/services/gamification
RUN npm ci --legacy-peer-deps
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/gamification

COPY --from=builder /app/services/gamification/dist ./dist
COPY --from=builder /app/services/gamification/package*.json ./
RUN npm ci --only=production --legacy-peer-deps

COPY --from=builder /app/services/gamification/drizzle ./drizzle
COPY --from=builder /app/services/gamification/scripts ./scripts
COPY --from=builder /app/services/gamification/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4006

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
