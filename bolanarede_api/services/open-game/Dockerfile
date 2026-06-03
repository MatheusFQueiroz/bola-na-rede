# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

# Copy monorepo base config (required for @shared/* path resolution)
COPY tsconfig.base.json ./

# Copy shared module source (compiled into dist alongside service)
COPY shared/ ./shared/

# Copy service source and package files
COPY services/open-game/ ./services/open-game/

# Install all dependencies (including devDeps for build)
WORKDIR /app/services/open-game
RUN npm ci --legacy-peer-deps

# Compile TypeScript
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

RUN apk add --no-cache dumb-init

WORKDIR /app/services/open-game

# Copy compiled output
COPY --from=builder /app/services/open-game/dist ./dist

# Copy package files and install ONLY production dependencies
COPY --from=builder /app/services/open-game/package*.json ./
RUN npm ci --only=production --legacy-peer-deps

# Copy Drizzle migration files
COPY --from=builder /app/services/open-game/drizzle ./drizzle

# Copy migration script
COPY --from=builder /app/services/open-game/scripts ./scripts

# Copy and make entrypoint executable
COPY --from=builder /app/services/open-game/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4004

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
