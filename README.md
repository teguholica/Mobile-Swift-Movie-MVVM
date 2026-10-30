# Mobile-Swift-Movie-MVVM

[![Platform: iOS 17+](https://img.shields.io/badge/Platform-iOS%2017%2B-blue.svg?style=flat-square)](https://developer.apple.com/ios/)
[![Swift: 5.10 / 6](https://img.shields.io/badge/Swift-5.10%20%2F%206-orange.svg?style=flat-square)](https://swift.org)
[![UI: SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple.svg?style=flat-square)](https://developer.apple.com/xcode/swiftui/)
[![Architecture: Clean MVVM](https://img.shields.io/badge/Architecture-Clean%20MVVM-green.svg?style=flat-square)](docs/adr/0001-clean-architecture-mvvm-with-swiftdata.md)
[![Persistence: SwiftData](https://img.shields.io/badge/Persistence-SwiftData-yellow.svg?style=flat-square)](https://developer.apple.com/documentation/swiftdata)
[![API: TMDB v4](https://img.shields.io/badge/API-The%20Movie%20Database-01d277.svg?style=flat-square)](https://www.themoviedb.org/)

A modern, native iOS movie discovery application built with **SwiftUI**, **Clean Architecture (MVVM)**, **SwiftData**, and the **Observation** framework. Powered by [The Movie Database (TMDB)](https://www.themoviedb.org/) API with **zero external third-party dependencies**.

---

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Configuration & API Key](#configuration--api-key)
  - [Running the App](#running-the-app)
- [Testing](#testing)
- [Attribution & Legal](#attribution--legal)

---

## Features

### Home & Discovery
- **Spotlight Hero Marquee**: Peeking carousel of Now Playing movies with cinematic backdrop imagery, gradient masks, and smooth paging.
- **Top Rated Showcase**: Visual ranking leaderboard featuring oversized numbers and high-resolution posters.
- **Popular Movies**: Infinite scrolling horizontal row with seamless pagination and deduplication.

### Search & Thematic Exploration
- **Live Debounced Search**: Instant movie searching with 400ms debouncing to minimize redundant network requests.
- **Category Browsing**: Multi-select category sheet with OR semantics, plus a pinned filter bar for year, rating, and sort.
- **Poster Grid**: Adaptive two-column responsive grid with integrated rating badges.

### Immersive Movie Detail
- **Stretchy Parallax Header**: Dynamic cinema backdrop that gracefully stretches on pull-down without white gap blowouts.
- **Film Stats**: Tabular display of duration, user rating score, and release year.
- **Floating Floating Action**: One-tap toggle to add or remove movies from favorites.

### Cast & Person Filmography
- **Tappable Cast**: Tapping any cast member opens a person screen while keeping the current navigation stack.
- **Info & Film Tabs**: Person biography, birthday, birthplace, and full acting filmography sorted newest-first.
- **Recursive Exploration**: Any film in the filmography opens its movie detail, allowing continuous discovery.

### Favorites & Offline Watchlist
- **SwiftData Persistence**: Local, high-performance offline storage isolated from network state.
- **Dual View Layout**: Seamless switching between 2-column Poster Grid and detailed List View.
- **Undoable Deletion Toast**: Soft-staged deletion with a 4-second interactive undo window before disk commit.

### Settings & Personalization
- **Theme Manager**: Custom appearance switching between System Default, Dark Mode (*Cinematic Obsidian*), and Light Mode (*Gallery Alabaster*).
- **Application Info**: Dynamic display of marketing version, build number, and TMDB legal attributions.

---

## Architecture

This project strictly adheres to **Clean Architecture** decoupled into three distinct layers, ensuring complete testability and separation of concerns:

```
┌────────────────────────────────────────────────────────┐
│                   Presentation (UI)                    │
│    SwiftUI Views  ◄───►  @Observable ViewModels        │
└───────────────────────────┬────────────────────────────┘
                            │ depends on
┌───────────────────────────▼────────────────────────────┐
│                      Domain                            │
│    Entities  ◄───  UseCases  ───►  Repository Protocols│
└───────────────────────────▲────────────────────────────┘
                            │ implemented by
┌───────────────────────────┴────────────────────────────┐
│                       Data                             │
│  Repository Impl  ◄───►  Remote API (URLSession)       │
│                   ◄───►  Local DB (SwiftData)          │
└────────────────────────────────────────────────────────┘
```

- **Zero External Dependencies**: Standard library only — `URLSession`, `async/await`, `@Observable`, and `SwiftData`.
- **Domain Independence**: The `Domain` layer has no dependencies on SwiftUI, SwiftData, or URLSession.
- **Swift Concurrency**: Fully modern Swift structured concurrency (`Sendable`, `@MainActor`, and asynchronous task lifecycles).

---

## Project Structure

```text
Mobile-Swift-Movie-MVVM/
├── Configuration/
│   ├── Config.xcconfig             # Base build settings and optional secret include
│   ├── Secrets.xcconfig.example    # Template for local TMDB token configuration
│   └── Info.plist                  # Generated Info.plist bridge for TMDB secrets
├── Mobile-Swift-Movie-MVVM/
│   ├── Data/
│   │   ├── Config/                 # TMDB network configurations & image resolution
│   │   ├── DataSource/
│   │   │   ├── Local/              # SwiftData models & local data sources
│   │   │   └── Remote/             # TMDB REST endpoint & URLSession service
│   │   ├── Model/                  # Codable Data Transfer Objects (DTOs)
│   │   └── Repository/             # Concrete implementations of Domain repositories
│   ├── Domain/
│   │   ├── Entity/                 # Pure business models (Movie, MovieDetail, Genre, PersonProfile)
│   │   ├── Repository/             # Repository protocol interfaces
│   │   └── UseCase/                # Single-responsibility business use cases
│   ├── UI/
│   │   ├── Common/                 # Design tokens, RatingBadge, ErrorView, LoadingView
│   │   ├── Detail/                 # Movie detail view & view model
│   │   ├── Favorites/              # Favorites screen, list/grid toggle, undo toast
│   │   ├── Home/                   # Spotlight marquee, Top-rated, Popular rows
│   │   ├── Person/                 # Person profile, Info/Film tabs, filmography rows
│   │   ├── Search/                  # Live search, year picker, filter and category sheets
│   │   ├── Settings/               # Theme manager, theme cards, version & attribution
│   │   └── TabBar/                 # Custom cinema tab bar navigation
│   └── Mobile_Swift_Movie_MVVMApp.swift # Application entry point
├── Mobile-Swift-Movie-MVVMTests/   # Unit tests (UseCases, ViewModels, Tokens, SwiftData)
├── Mobile-Swift-Movie-MVVMUITests/ # Launch and snapshot UI tests
└── docs/
    └── adr/                        # Architecture Decision Records
```

---

## Getting Started

### Prerequisites

- **macOS Sonoma 14.0+**
- **Xcode 16.0+**
- **iOS 17.0+ Simulator or Device**

### Configuration & API Key

The app connects to **The Movie Database (TMDB)**. For security, API keys are excluded from source control via `.xcconfig`:

1. Sign up for a free TMDB account at [themoviedb.org](https://www.themoviedb.org/).
2. Request an API key in your account settings to get your **v4 API Read Access Token**.
3. Create your local secrets configuration file:
   ```bash
   cp Configuration/Secrets.xcconfig.example Configuration/Secrets.xcconfig
   ```
4. Open `Configuration/Secrets.xcconfig` and enter your token:
   ```xcconfig
   TMDB_API_READ_ACCESS_TOKEN = your_tmdb_read_access_token_here
   ```
5. *(Optional)* Alternatively, set `TMDB_API_READ_ACCESS_TOKEN` in your environment variables or Xcode scheme run arguments.

> [!NOTE]
> `Configuration/Secrets.xcconfig` is gitignored by default and will never be committed to source control.

### Running the App

1. Clone the repository:
   ```bash
   git clone https://github.com/teguholica/Mobile-Swift-Movie-MVVM.git
   cd Mobile-Swift-Movie-MVVM
   ```
2. Open `Mobile-Swift-Movie-MVVM.xcodeproj` in Xcode:
   ```bash
   xed .
   ```
3. Select an iOS 17+ Simulator (e.g., iPhone 16 / iPhone 17) and press **⌘R** to build and run.

---

## Testing

The codebase includes comprehensive unit tests verifying Use Cases, ViewModels, SwiftData persistence, and Token resolution.

Run tests directly in Xcode (**⌘U**) or via command line:

```bash
xcodebuild test \
  -project Mobile-Swift-Movie-MVVM.xcodeproj \
  -scheme Mobile-Swift-Movie-MVVM \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:Mobile-Swift-Movie-MVVMTests \
  -quiet
```

---

## Attribution & Legal

This product uses the TMDB API but is not endorsed or certified by TMDB.

<p align="left">
  <a href="https://www.themoviedb.org/">
    <img src="https://www.themoviedb.org/assets/2/v4/logos/v2/blue_short-8e7b30f73a4020692ccca4c88bafe5dcb6f8a62a4c6bc55cd9cc82ff2e9797cc.svg" width="120" alt="TMDB Logo" />
  </a>
</p>
