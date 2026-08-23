# Local/compose image only - see services/ai-copilot/Dockerfile's comment;
# same shape, this service's own port/healthcheck.

FROM node:20-alpine

RUN apk add --no-cache curl

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY . .

EXPOSE 4008

HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=5 \
  CMD curl -f http://localhost:4008/health || exit 1

CMD ["npm", "start"]
