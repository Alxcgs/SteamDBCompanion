# Architecture - SteamDB Companion App

## Overview
This application is a native iOS companion for SteamDB, built with Swift and SwiftUI. It follows a Clean Architecture approach with MVVM.

## Tech Stack
- **Language**: Swift 5.10+
- **UI Framework**: SwiftUI
- **Minimum iOS Version**: iOS 17.0
- **Concurrency**: Swift Concurrency (async/await)
- **Dependency Management**: Swift Package Manager (SPM)

## High-Level Modules

### App
The application entry point and composition root.

### Core
Contains foundational logic and services:
- **Networking**: Generic HTTP client.
- **SteamDBDataSource**: Data access layer (API/HTML parsing).
- **Models**: Domain entities.
- **Cache**: Data persistence.

### Features
Contains the UI and business logic for specific features:
- **Home**: Dashboard and trending.
- **Search**: App search and filtering.
- **AppDetails**: Detailed view of apps/games.
- **Charts**: Statistical charts.
- **Settings**: User preferences.

### LiquidGlass
A custom design system module implementing the "Liquid Glass" aesthetic:
- Glass-like materials and backgrounds.
- Neon glows and highlights.
- Custom UI components (Cards, Buttons).

### SharedUI
Reusable UI components that are not specific to the "Glass" theme (e.g., generic lists, loading states).

## Data Flow
1. **View** requests data from **ViewModel**.
2. **ViewModel** requests data from **SteamDBDataSource**.
3. **SteamDBDataSource** checks **Cache**.
4. If missing/stale, calls **NetworkingService** or **HTMLParser**.
5. Data is returned up the chain to the **View**.

## Error Handling
- Structured `AppError` types.
- User-friendly error messages in UI.
- Retry mechanisms for network requests.
