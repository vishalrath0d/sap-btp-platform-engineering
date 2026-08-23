# Local/compose image only - same shape as the other plain-Express
# services here (api-gateway, legacy-erp-gateway, spend-anomaly-detector):
# a small stateless Node process, no build step needed since there's no
# bundler/transpiler in this stack. Differs from procurement-core's
# Dockerfile only in that there's no CAP framework involved.

FROM node:20-alpine

RUN apk add --no-cache curl

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY . .

EXPOSE 4005

HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=5 \
  CMD curl -f http://localhost:4005/health || exit 1

CMD ["npm", "start"]
