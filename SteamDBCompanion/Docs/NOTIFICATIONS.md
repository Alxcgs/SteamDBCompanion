# Notifications System

## Overview
The app uses APNs (Apple Push Notification service) to deliver alerts about price drops and significant game updates.

## Architecture
- **NotificationRegistrationService**: Handles APNs token registration.
- **NotificationRouter**: Handles deep linking from notification payloads.

## Payload Structure
```json
{
  "aps": {
    "alert": {
      "title": "Price Drop: Half-Life 3",
      "body": "Now 50% off!"
    },
    "sound": "default"
  },
  "type": "price_drop",
  "appId": "123456"
}
```

## Privacy & Permissions
- We use a "Pre-permission" screen to explain the value of notifications before requesting system permission.
- Users can manage preferences in Settings.
