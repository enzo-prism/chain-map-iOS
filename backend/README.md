# Chain Map Backend

A lightweight Node 20 + TypeScript service that ingests official DOT road
condition data, normalizes it, and serves a single JSON API for the iOS app.

## Sources
- Caltrans QuickMap chain controls (KML): https://quickmap.dot.ca.gov/data/cc.kml
- Nevada 511 road conditions (JSON): https://www.nvroads.com/api/v2/get/roadconditions

## Setup
1. Install dependencies:
   ```bash
   npm install
   ```
2. Copy the env template and fill in keys:
   ```bash
   cp .env.example .env
   ```
3. Run the server:
   ```bash
   npm run dev
   ```

## Environment variables
- `NEVADA_511_API_KEY`: required to call Nevada 511.
- `ALLOWED_INGEST_TOKEN`: shared secret for POST `/v1/ingest`.
- `PORT`: server port (default 8787 if unset).

## Scripts
- `npm run dev`: run the API server with hot reload.
- `npm run ingest`: run ingestion once and write cache.
- `npm run build` / `npm start`: build and run compiled output.
- `npm test`: run unit tests.

## API
- `GET /v1/health`
- `GET /v1/corridors`
- `GET /v1/events?corridor=<corridorId>`
- `POST /v1/ingest` (requires `Authorization: Bearer <ALLOWED_INGEST_TOKEN>`)

## Caching
The service writes `data/last_known_good.json` and serves it when upstream
sources fail. Responses include `generatedAt` so clients can detect staleness.

## Scheduling ingestion
You can run ingestion via:
- A scheduler calling `npm run ingest`.
- An HTTP scheduler calling `POST /v1/ingest` with the bearer token.

Example (cron on a typical host):
```
*/3 * * * * cd /path/to/backend && /usr/bin/env NEVADA_511_API_KEY=... ALLOWED_INGEST_TOKEN=... npm run ingest
```

Example (GitHub Actions):
```yaml
on:
  schedule:
    - cron: "*/3 * * * *"

jobs:
  ingest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm install
        working-directory: backend
      - run: npm run ingest
        working-directory: backend
        env:
          NEVADA_511_API_KEY: ${{ secrets.NEVADA_511_API_KEY }}
          ALLOWED_INGEST_TOKEN: ${{ secrets.ALLOWED_INGEST_TOKEN }}
```
