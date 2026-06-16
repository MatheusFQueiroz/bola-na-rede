# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

COPY tsconfig.base.json ./
COPY shared/ ./shared/
COPY services/notification/ ./services/notification/

WORKDIR /app/services/notification
RUN npm ci --legacy-peer-deps
# compiles to /app/dist/services/notification (outDir: ../../dist/services/notification)
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/services/notification/package*.json ./services/notification/
RUN cd /app/services/notification && npm ci --only=production --legacy-peer-deps

COPY services/notification/scripts ./services/notification/scripts
COPY services/notification/docker-entrypoint.sh ./services/notification/
RUN chmod +x /app/services/notification/docker-entrypoint.sh

EXPOSE 4010

ENTRYPOINT ["dumb-init", "--"]
CMD ["/app/services/notification/docker-entrypoint.sh"]
