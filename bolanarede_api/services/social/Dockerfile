# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/social/ ./services/social/

WORKDIR /app/services/social
RUN npm ci --legacy-peer-deps
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/social

COPY --from=builder /app/services/social/dist ./dist
COPY --from=builder /app/services/social/package*.json ./
RUN npm ci --only=production --legacy-peer-deps

COPY --from=builder /app/services/social/drizzle ./drizzle
COPY --from=builder /app/services/social/scripts ./scripts
COPY --from=builder /app/services/social/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4005

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
