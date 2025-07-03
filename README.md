# CryptoTracker

CryptoTracker is an iOS application that allows users to track real-time cryptocurrency prices, view detailed charts, and manage a list of favorite coins.

---

## Architecture

CryptoTracker follows the **MVVM+C** (Model-View-ViewModel + Coordinator) pattern and is organized into clean, modular layers:

### Layered Structure:

- ** Presentation Layer**  
  Handles UI rendering, user interactions, and business logic.

- ** Model Layer**  
  Contains data models, parsing logic (Decodable), and domain representations.

- ** Service Layer**  
  Responsible for:
  - Networking (API abstraction over `URLSession`)
  - Offline caching
  - Local notifications

- ** Application Layer**  
  Handles:
  - App entry point (`AppDelegate`, `SceneDelegate`)
  - App-wide coordinator setup

- ** Core Layer**  
  Shared logic and utilities:
  - Custom Publishers
  - Helper managers
  - Formatters

**Dependency Injection** is implemented via initializers, ensuring testability and separation of concerns.


## Getting Started

### Prerequisites

- Xcode 16+
- iOS 16.0+
- Swift 5.9+

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/CryptoTracker.git
   cd CryptoTracker

## Challenges & Solutions

### iOS 16.0 Deployment Target
The app requires **iOS 16.0** to use **SwiftUI Charts** for rendering price history graphs.

### CoinGecko API Rate Limits
CoinGecko enforces strict rate limits (50 requests/minute per IP). To handle this:

- The first crypto page is **preloaded after a 1-minute delay**
- Pages are **fetched sequentially**, with time gaps to avoid rate limits
- Favorite coin prices are **updated every 5 minutes**
- If a favorite coin changes ±5%, a **local notification** is triggered

### Preloading Strategy
The app uses a `CryptocurrencyPreloader` that:

- Waits 1 minute before initial fetch
- Loads pages until no more data or cancellation
- Saves all data for offline access

### Reactive Updates
A background task checks favorite coins every 5 minutes. If any change exceeds ±5%, the app triggers a **local alert** using `UNUserNotificationCenter`.

### Complex Fetch Logic
Managing API limits while ensuring live updates and caching required:

- Retry logic
- Delayed pagination
- Memory-aware updates




