# ---- Builder ----
FROM node:22-alpine AS builder
WORKDIR /app

# Copy monorepo base config (required for @shared/* path resolution)
COPY tsconfig.base.json ./

# Copy shared module source (compiled into dist alongside service)
COPY shared/ ./shared/

# Copy service source and package files
COPY services/identity/ ./services/identity/

# Install all dependencies (including devDeps for build)
WORKDIR /app/services/identity
RUN npm ci

# Compile TypeScript (shared module and service compiled together into dist/)
RUN npm run build

# ---- Runner ----
FROM node:22-alpine AS runner

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

WORKDIR /app/services/identity

# Copy compiled output (includes shared/src compiled alongside service)
COPY --from=builder /app/services/identity/dist ./dist

# Copy package files and install ONLY production dependencies
COPY --from=builder /app/services/identity/package*.json ./
RUN npm ci --only=production

# Copy Drizzle migration files
COPY --from=builder /app/services/identity/drizzle ./drizzle

# Copy migration script
COPY services/identity/scripts ./scripts

# Copy and make entrypoint executable
COPY services/identity/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 4001

ENTRYPOINT ["dumb-init", "--"]
CMD ["./docker-entrypoint.sh"]
