# API Integration Strategy

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
