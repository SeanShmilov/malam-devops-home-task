# Multi-stage production Dockerfile for nodejs-demoapp
# Stage 1: Dependencies and Build
FROM node:22-alpine AS builder

WORKDIR /usr/src/app

# Copy dependency specifications
COPY package*.json ./

# Install production dependencies only
RUN npm install --omit=dev

# Stage 2: Runtime image (Active Node LTS, minimal footprint)
FROM node:22-alpine

# Remove package managers from production runtime to eliminate attack surface & CVEs
RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx /opt/yarn*

# Set non-root environment & node production mode
ENV NODE_ENV=production
ENV PORT=3000

WORKDIR /usr/src/app

# Install dumb-init to properly handle PID 1 signals
RUN apk add --no-cache dumb-init

# Copy node modules from builder stage
COPY --chown=node:node --from=builder /usr/src/app/node_modules ./node_modules

# Copy application source files
COPY --chown=node:node server.js primes.js index.html package*.json ./
COPY --chown=node:node Images ./Images

# Use non-root node user (standard in official node image)
USER node

# Document port
EXPOSE 3000

# Container healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/ || exit 1

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]

