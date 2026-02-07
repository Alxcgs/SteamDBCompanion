# SteamDB Companion — Regression QA Report

Date: 2026-02-07  
Scope: full regression for all screens, menus, submenus, routes, and critical plan items.

## Automated verification

- `xcodebuild -scheme SteamDBCompanion -project SteamDBCompanion.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' build`  
Status: PASS

- `npm run typecheck` in `backend/`  
Status: PASS

- `./scripts/check_parity_matrix.sh`  
Status: PASS (`Routes aligned: 32`)

- `xcodebuild ... test`  
Status: NOT RUN (scheme has no configured test action)

## Critical fixes status

1. Utility route correctness
- Added route-level URL overrides and fallbacks for `/events`, `/year`, `/login`, `/wishlist`, `/news`.
- Broken utility routes no longer depend on invalid `steamdb.info/<path>` paths.
- Status: IMPLEMENTED

2. Web shell overlap and input blocking
- Reworked `WebFallbackShellView` to clean overlayless mode.
- Removed always-on top overlay, switched inset adjustment to automatic, added web-history-aware back action.
- Added optional fallback URL handling for route-level 404/rate-limit content.
- Status: IMPLEMENTED

3. Native route data separation
- Added `fetchCollection(kind:)` to datasource protocol and implementations.
- `NativeRouteCollectionView` now maps each route to dedicated `CollectionKind` instead of shared top-sellers/trending switch.
- Updated row navigation to destination-based links (fixes non-opening tap behavior).
- Status: IMPLEMENTED

4. Localization and currency behavior
- Fixed runtime translation lookup (`L10n`) to honor app language override (`system/en/uk`).
- Backend parser no longer hardcodes `USD`; added locale-aware default currency mapping and symbol/code parsing.
- Locale params (`cc`, `l`) continue propagating through gateway + backend routes.
- Status: IMPLEMENTED

5. Updates feed diversification
- Kept global feed and added wishlist-derived app news via Steam app news API.
- Split output into "Wishlist News" and "Steam News" sections with dedupe and date ordering.
- Status: IMPLEMENTED

## Screen-by-screen checklist (code-path + build validated)

- Home: PASS  
Trending/top sellers loading + empty states + dynamic top-seller expansion logic present.

- Search: PASS  
Debounce, error, no-result, and AppDetails navigation path validated in code.

- App Details: PASS  
Bottom-sheet store chooser, chart drill-down entry, store browser destinations, Steam-sign-in/wishlist state aware action logic.

- Wishlist: PASS  
Signed-in/out states, sync status card, retry action, sync error visibility, last synced timestamp; redundant double-load on first open removed.

- Updates: PASS  
Native diff history + tracked apps + hybrid news (wishlist + global) + refresh/clear actions.

- Settings: PASS  
Theme (system/light/dark), language, store country/language, full website mode toggle, Steam account entry points.

- Web Fallback Shell: PASS  
No persistent overlap header; web-history back-or-dismiss behavior; route fallback support.

- Routing parity: PASS  
All declared routes mapped and mode-assigned.

## Known non-blocking items

- Swift warning in `InAppAlertEngine` about actor-isolated default initializer remains (does not fail build).
- No dedicated XCTest action is configured in project scheme; regression is validated via build/typecheck/parity and code-path verification.

## Manual validation matrix (must run on simulator + device)

1. Utility routes (`/events`, `/year`, `/wishlist`)
- Open via Explore -> All Pages.
- Expected: valid page load; if primary route fails, fallback URL opens automatically.

2. Steam login and wishlist sync
- Open Wishlist tab -> Sign in with Steam -> complete login/2FA -> return to app -> trigger sync.
- Expected: auth state changes to signed-in, wishlist loads, last sync timestamp visible.

3. Localization and currency
- Settings -> Language (`English`/`Ukrainian`) and Store country change.
- Expected: visible UI strings switch and price formatting/content refresh after cache invalidation.

4. Store open bottom sheet
- App Details -> Store.
- Expected: bottom sheet always opens from bottom (no anchored callout), both actions work.

5. Web fallback back behavior
- Open any fallback route -> navigate web pages -> press back.
- Expected: navigates web history; if no history, closes web screen to prior native screen.
