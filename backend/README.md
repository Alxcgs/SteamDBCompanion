# SteamDB Companion Backend (Cloudflare Free Tier)

This worker provides a free gateway API for the iOS app:

- `GET /v1/navigation/routes`
- `GET /v1/home`
- `GET /v1/search?q=&page=`
- `GET /v1/apps/:id/overview`
- `GET /v1/apps/:id/charts?range=`
- `GET /v1/collections/:kind`
- `GET /v1/watchlist/:installationId`
- `PUT /v1/watchlist/:installationId`
- `GET /v1/health`

## 1) Install

```bash
npm install
```

## 2) Create free KV namespaces

```bash
npx wrangler kv namespace create ROUTE_CACHE
npx wrangler kv namespace create ROUTE_CACHE --preview
npx wrangler kv namespace create USER_WATCHLISTS
npx wrangler kv namespace create USER_WATCHLISTS --preview
```

Copy generated IDs into `wrangler.toml`.

## 3) Local run

```bash
cp .dev.vars.example .dev.vars
npm run dev
```

## 4) Deploy (free workers.dev)

```bash
npm run deploy
```

## Notes

- On upstream failures or `429`, the worker serves stale KV cache where available.
- Watchlist sync is stored in `USER_WATCHLISTS` KV.
- Parser is intentionally lightweight and should be extended with fixture tests as markup changes.
