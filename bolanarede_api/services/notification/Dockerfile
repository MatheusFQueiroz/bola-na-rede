FROM node:22-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/notification/ ./services/notification/

RUN npm ci --legacy-peer-deps
RUN npm run build --workspace=services/notification

# ── runner ────────────────────────────────────────────────────────────────────
FROM node:22-alpine AS runner

WORKDIR /app

COPY --from=builder /app/package.json /app/package-lock.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/services/notification/scripts ./services/notification/scripts
COPY --from=builder /app/services/notification/docker-entrypoint.sh ./services/notification/

RUN chmod +x /app/services/notification/docker-entrypoint.sh

EXPOSE 4010

ENTRYPOINT ["/app/services/notification/docker-entrypoint.sh"]
