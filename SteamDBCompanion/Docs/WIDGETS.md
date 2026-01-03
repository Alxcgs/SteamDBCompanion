# iOS Widgets Guide

## Overview
SteamDB Companion includes Home Screen, Lock Screen, and **Interactive Widgets (iOS 17+)** to show trending Steam games at a glance.

## Widget Types

### Interactive Features (iOS 17+) 🆕
Medium widgets now support **interactive buttons**:
- **Refresh button**: Tap to update trending data immediately
- **Wishlist button**: Add/remove games from wishlist without opening app
- Uses App Intents for system-level integration

### Home Screen Widgets

#### Small Widget (2x2)
- Shows the #1 trending game
- Displays player count
- Updates every 30 minutes

#### Medium Widget (4x2)
- Shows top 3 trending games
- Displays player counts for each
- Clean list layout
- Updates every 30 minutes

### Lock Screen Widgets (iOS 16+)

#### Rectangular Widget
- Shows top 2 trending games with player counts
- Compact layout for lock screen

#### Circular Widget
- Shows trending icon with player count
- Minimal, glanceable information

## Technical Implementation

### Timeline Updates
- Widgets refresh every 30 minutes
- Uses `TimelineProvider` for automatic updates
- Shared data container (optional) for live updates from main app

### Data Source
Widgets can fetch data from:
1. **Shared UserDefaults Suite** (recommended for production)
2. **Network requests** (with rate limiting)
3. **Mock data** (current implementation for demo)

### Adding to Project

1. **Create Widget Extension**:
   - In Xcode: File > New > Target > Widget Extension
   - Name: "SteamDBWidgets"
   - Include Configuration Intent: No (for static widgets)

2. **Add App Group** (for shared data):
   - Enable App Groups capability in main app
   - Enable App Groups capability in widget extension
   - Use group ID: `group.com.yourteam.steamdb`

3. **Share Data**:
```swift
// In main app - save trending data
let userDefaults = UserDefaults(suiteName: "group.com.yourteam.steamdb")
userDefaults?.set(encodedData, forKey: "trendingGames")

// In widget - read trending data
let userDefaults = UserDefaults(suiteName: "group.com.yourteam.steamdb")
let data = userDefaults?.data(forKey: "trendingGames")
```

## Design

Widgets use:
- Gradient backgrounds (blue to purple)
- SF Symbols icons
- Clear typography
- High contrast for readability

## Future Enhancements

- [ ] Interactive widgets (iOS 17+) for quick actions
- [ ] Different widget configurations (most played, new releases)
- [ ] Customizable game selection
- [ ] Rich complications for Apple Watch

## Testing

Test widgets in:
- Xcode widget preview
- Home screen (long press > Edit Home Screen)
- Lock screen (iOS 16+)
- Widget gallery

## Performance

- Minimal network usage
- Efficient timeline updates
- Lightweight views
- No background processing

## Interactive Widgets (iOS 17+)

### App Intents
Widgets use App Intents framework for interactive actions:

#### Toggle Wishlist Intent
```swift
Button(intent: ToggleWishlistIntent(appID: 730, appName: "CS2")) {
    Image(systemName: "heart")
}
```

#### Refresh Data Intent
```swift
Button(intent: RefreshDataIntent()) {
    Image(systemName: "arrow.clockwise")
}
```

### Supported Actions
- **Add to Wishlist**: Tap heart icon to save game
- **Remove from Wishlist**: Tap again to remove
- **Refresh Data**: Update trending games manually
- **Open Game**: Tap game name to view details in app

### Implementation
Interactive widgets require:
1. App Intents framework
2. iOS 17.0+ deployment target
3. Intent definitions in widget code
4. Proper entitlements

---

**Note**: Widgets are read-only on iOS 16. Interactive features require iOS 17+.
