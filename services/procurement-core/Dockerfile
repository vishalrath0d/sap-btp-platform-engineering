# Local/compose image only - runs `cds-serve` (via `npm start`) directly
# against source, using this app's default cds.requires profile (sqlite
# db, mocked auth - see package.json's "cds" section), the same profile
# `npm start`/`cds watch` use outside Docker. Production packaging is
# deliberately different: BTP deployment goes through `cds build
# --production` + `mbt build` + `cf deploy` against a real HANA instance
# and real XSUAA (see .github/workflows/procurement-core-ci.yml and
# mta.yaml) - none of that happens here. This file exists so
# docker-compose can run the whole service graph locally, nothing more.

FROM node:20-alpine

RUN apk add --no-cache curl

WORKDIR /app

COPY package.json package-lock.json ./
# better-sqlite3 (@cap-js/sqlite's dependency) compiles a native addon at
# install time - node-gyp needs python3/make/g++, which node:20-alpine
# doesn't ship (real build failure hit here, not a hypothetical). Installed
# as a virtual package and removed again in the same layer so the compiled
# .node binary stays but the toolchain doesn't bloat the final image.
RUN apk add --no-cache --virtual .build-deps python3 make g++ \
  && npm ci --omit=dev \
  && apk del .build-deps

COPY . .

# README's "Run it locally" already documents this as a required step
# before `npm start` outside Docker too (`npx cds deploy` creates
# db.sqlite and loads db/data/*.csv) - cds-serve (production-style start)
# doesn't auto-deploy the way `cds watch` does, so it has to happen here
# at build time or the container starts against a schema-less db and every
# query 500s ("no such table") - real error hit building this image.
# Calling the local `cds-deploy` binary directly, not `npx cds deploy` -
# npx failed here with "could not determine executable to run" (no
# network access in this build to fall back on resolving a package), and
# there is no plain `cds` binary either: `@sap/cds` (a real, non-dev
# dependency here) ships standalone bins - cds-deploy, cds-serve, etc. -
# the full `cds` CLI is a separate package, `@sap/cds-dk`, deliberately
# not installed here (it's a dev-time tool, not a runtime dependency).
# Verified against this image's actual node_modules/.bin, not assumed.
RUN ./node_modules/.bin/cds-deploy

EXPOSE 4004

# CAP's cds-serve exposes /health by default (built in for CF/K8s liveness
# probes).
HEALTHCHECK --interval=5s --timeout=3s --start-period=15s --retries=6 \
  CMD curl -f http://localhost:4004/health || exit 1

CMD ["npm", "start"]
