# Install dependencies only when needed
FROM node:18-alpine AS deps
# FROM alpine:latest
# RUN apk update && apk upgrade
RUN apk add --no-cache libc6-compat
RUN apk update
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Rebuild the source code only when needed
FROM node:18-alpine AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules

COPY . .

RUN yarn build:prod

# Production image, copy all the files and run next
FROM node:18-alpine AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 fegroup
RUN adduser --system --uid 1001 feuser

COPY --from=builder /app/node_modules ./node_modules
# You only need to copy next.config.js if you are NOT using the default configuration
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
# COPY --from=builder --chown=feuser:fegroup /app/.next/standalone ./
COPY --from=builder --chown=feuser:fegroup /app/.next/static ./.next/static

USER feuser

EXPOSE 3000

ENV PORT 3000

CMD ["npm", "run", "start"]