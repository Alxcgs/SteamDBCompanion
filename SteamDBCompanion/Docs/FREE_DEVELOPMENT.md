# Free Development Runbook (0$)

This project is configured for a fully free workflow.

## Distribution (No TestFlight)

- Use Xcode + personal Apple ID (`Personal Team`) for sideload.
- Signed builds expire in ~7 days and must be reinstalled.
- For continuous testing, use iOS Simulator plus periodic sideload on device.

## Notifications

- APNs push is disabled in free mode.
- The app uses in-app alerts generated after refresh/open.

## Backend

- Deploy `backend/` on Cloudflare Workers free tier.
- Storage:
  - `ROUTE_CACHE` KV for endpoint caching.
  - `USER_WATCHLISTS` KV for watchlist sync.
- If SteamDB rate limits upstream requests, worker responds with stale cached payload where available.

## Setup checklist

1. Install Xcode from App Store.
2. Configure your Apple ID in Xcode Accounts.
3. Open project and select Personal Team for signing.
4. Create Cloudflare KV namespaces and update `backend/wrangler.toml`.
5. Deploy worker and set app gateway URL:
   - Environment variable: `STEAMDB_GATEWAY_URL`
   - or `UserDefaults` key: `SteamDBGatewayURL`

## Legal/branding

- Use name: `SteamDB Companion (unofficial)`.
- Keep disclaimer in-app: "Not affiliated with Valve or SteamDB."
