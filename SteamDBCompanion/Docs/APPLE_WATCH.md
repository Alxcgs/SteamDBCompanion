# Apple Watch Guide

## Overview
SteamDB Companion supports Apple Watch with rich complications showing trending Steam games.

## Complication Types

### Circular
- Trending icon with player count
- Compact, glanceable
- Perfect for modular faces

### Rectangular
- Game name + player count
- Most information density
- Best for Infograph faces

### Inline
- Text-only format
- Shows "🎮 Game: Players"
- Works with all watch faces

### Corner (Series 4+)
- Player count in corner
- Icon in center
- Clean, minimal design

## Features

### Data Display
- Shows #1 trending game
- Current player count
- Auto-refreshes hourly

### Interaction
- Tap to open main app on iPhone
- Quick glance at gaming trends
- Always up-to-date information

## Setup Instructions

### 1. Add watchOS Target
In Xcode:
1. File > New > Target
2. Select "watchOS" > "App"
3. Name: "SteamDB Watch"
4. Include Complications: Yes

### 2. Configure Complications
1. Add `TrendingComplication.swift` to Watch target
2. Configure Info.plist:
   - Add `CLKComplicationSupportedFamilies`
   - Enable all complication types

### 3. Share Data (Optional)
```swift
// Use App Groups to share data
let userDefaults = UserDefaults(suiteName: "group.com.yourteam.steamdb")
userDefaults?.set(encodedData, forKey: "trendingWatchData")
```

## Complication Families Support

| Family | Size | Best For |
|--------|------|----------|
| **Circular** | Small circle | Modular, Utility |
| **Rectangular** | Wide rectangle | Infograph Modular |
| **Inline** | Text only | All faces (iOS 16+) |
| **Corner** | Corner placement | Infograph (Series 4+) |

## Design Guidelines

### Visual Hierarchy
- Player count is primary
- Game name is secondary
- Icon for quick recognition

### Color & Contrast
- Uses system tint colors
- High contrast for readability
- Supports always-on display

### Typography
- Bold numbers for quick scanning
- System font for consistency
- Appropriate sizing per family

## Update Frequency

- **Timeline Policy**: Update after 1 hour
- **Background Refresh**: Automatic
- **Budget**: ~50 updates/day (watchOS limit)

## Performance

### Optimization
- Minimal data fetching
- Efficient timeline generation
- Low memory footprint
- Battery-friendly updates

### Data Usage
- Reuses iOS app data when possible
- Minimal network requests
- Cached responses

## Testing

### Simulator
- Test all complication families
- Preview on different watch faces
- Verify data refresh

### Device
- Install on paired Apple Watch
- Add complication to face
- Monitor hourly updates
- Test tap behavior

## Future Enhancements

- [ ] Multiple game complications
- [ ] Price drop alerts
- [ ] Favorite games tracking
- [ ] Standalone Watch app (independent)

## Limitations

- Read-only complications
- No direct interaction (opens iPhone app)
- Hourly refresh (not real-time)
- Depends on iPhone for data

## Troubleshooting

### Complication Not Showing
1. Verify watch target includes files
2. Check Info.plist configuration
3. Ensure timeline provider returns data
4. Rebuild and reinstall

### Data Not Updating
1. Check background refresh settings
2. Verify App Group configuration
3. Monitor timeline policy
4. Check network connectivity

---

**Note**: Requires paired Apple Watch (Series 4+ for corner complications, any model for others).
