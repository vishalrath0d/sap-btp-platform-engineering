# Local/compose image only - see services/ai-copilot/Dockerfile's comment;
# same shape, this service's own port/healthcheck. In a real landscape
# this service is Kyma-deployed and event-driven (subscribes to SAP Event
# Mesh, no HTTP webhook - see src/server.js's comment on
# /events/purchase-order-created), but the image itself is the same kind
# of plain containerized Node process either way - only how it's deployed
# and triggered differs.

FROM node:20-alpine

RUN apk add --no-cache curl

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY . .

EXPOSE 4006

HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=5 \
  CMD curl -f http://localhost:4006/health || exit 1

CMD ["npm", "start"]
