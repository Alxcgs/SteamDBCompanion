# API Integration Strategy

## Current v1 Gateway Architecture

The iOS app now consumes a Cloudflare Worker gateway (`backend/`) instead of parsing SteamDB HTML directly on-device.

### Gateway endpoints
- `GET /v1/navigation/routes`
- `GET /v1/home`
- `GET /v1/search?q=&page=`
- `GET /v1/apps/:id/overview`
- `GET /v1/apps/:id/charts?range=`
- `GET /v1/collections/:kind`
- `GET /v1/watchlist/:installationId`
- `PUT /v1/watchlist/:installationId`
- `GET /v1/health`

### Availability policy
- Worker returns fresh data when SteamDB is reachable.
- If upstream fails or returns `429`, worker serves stale cache from KV (`route_cache`) when available.
- iOS must treat stale responses as degraded but valid.

## Data Sources

### 1. SteamDB Public Data
We will utilize any available public endpoints.
*Note: SteamDB does not have a full public API.*

### 2. HTML Parsing (Scraping)
For data not available via JSON, we will parse the HTML of SteamDB pages.
- **Library**: SwiftSoup (or similar standard HTML parser).
- **Strategy**:
    - Fetch page HTML via `URLSession`.
    - Extract relevant data points (prices, player counts, history).
    - Map to domain models.

### 3. Mock Data
To ensure development velocity and stability, we will maintain a comprehensive `MockSteamDBDataSource`.
- Allows testing UI without network.
- Provides consistent data for previews.

## Limitations & Ethics
- **Rate Limiting**: We will implement client-side rate limiting to avoid overwhelming SteamDB servers.
- **Caching**: Aggressive caching (memory & disk) to minimize requests.
- **User Agent**: We will use a distinct User-Agent string to identify the app.

## Fallbacks
If data cannot be parsed or fetched:
- Show cached data if available.
- Show a graceful error message.
- Provide a link to open the page in an in-app browser.
