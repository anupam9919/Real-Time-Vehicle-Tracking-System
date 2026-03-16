# Real-Time Vehicle Tracking System

A comprehensive Flutter-based real-time vehicle tracking application designed to cater to three primary roles: Users (Students), Drivers, and Administrators. This system leverages Firebase Realtime Database for live location updates and Geolocator for precise GPS tracking.

## 🚀 Features

- **Role-Based Access Control**: Secure login system distinguishing between Administrators, Drivers, and Users (Students).
- **Live Location Tracking**: Drivers broadcast real-time GPS coordinates (every 5 seconds), instantly reflected for users tracking vehicles.
- **ETA & Distance Calculation**: Real-time ETA computed using live GPS speed and straight-line distance (Vincenty formula via Geolocator).
- **Nearest Bus Stop Finder**: Automatically detects user's location and finds the closest boarding point with walking ETA.
- **Admin Dashboard**: Full CRUD for vehicles, drivers, and boarding points.
- **Driver Dashboard**: Dedicated interface with live GPS transmission toggle, speed display, and SOS emergency button.
- **Premium Glassmorphic UI**: Dark-themed, frosted-glass design with smooth animations powered by Flutter Animate.
- **CI/CD Pipeline**: Automated APK builds and GitHub Releases via GitHub Actions on version tags.

## 🛠 Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Framework** | Flutter (Dart SDK `≥3.3.1 <4.0.0`) |
| **Backend** | Firebase Realtime Database |
| **Authentication** | Firebase Auth |
| **State Management** | Riverpod (`flutter_riverpod`) |
| **Routing** | GoRouter (`go_router`) |
| **Location / GPS** | Geolocator |
| **Code Generation** | Freezed + JSON Serializable |
| **UI / Design** | Google Fonts, Flutter Animate, Timeline Tile |
| **Logging** | Dart `logging` package with custom `AppLogger` |
| **CI/CD** | GitHub Actions (automated APK build + release) |

## 🏗 Architecture

The project follows a **Clean Architecture** pattern with feature-based modules:

```mermaid
graph TD
    subgraph Presentation
        SignIn[Sign-In Screen]
        UserApp[Student Interface]
        DriverApp[Driver Dashboard]
        AdminApp[Admin Panel]
        Providers[Riverpod Providers]
    end

    subgraph Domain
        UseCases[Use Cases]
        Repos[Repository Interfaces]
        Entities[Entities]
    end

    subgraph Data
        RepoImpl[Repository Implementations]
        DataSources[Remote Data Sources]
        Models[Data Models - Freezed]
    end

    subgraph Core
        LocationSvc[Location Service]
        DistUtils[Distance Utils - Haversine]
        EtaUtils[ETA Utils]
        Theme[App Theme]
        Router[GoRouter]
    end

    subgraph External
        Firebase[(Firebase RTDB)]
        Geolocator[Geolocator API]
    end

    Presentation --> Providers
    Providers --> UseCases
    UseCases --> Repos
    RepoImpl --> DataSources
    DataSources --> Firebase
    DriverApp --> Geolocator
    LocationSvc --> Geolocator
```

## 🔄 Flow Diagrams

### Authentication Flow
```mermaid
sequenceDiagram
    participant User
    participant App as Flutter App
    participant Env as .env Configuration
    participant Firebase as Firebase DB

    User->>App: Enter ID, Password, and Role
    App->>App: Validate Inputs
    
    alt Role == Student / Admin
        App->>Env: Check against STUDENT_ID/ADMIN_ID
        alt Match
            App->>User: Grant Access (Home / Admin Page)
        else No Match
            App->>User: Show Invalid Credentials Error
        end
    else Role == Driver
        App->>Firebase: Fetch driver details (drivers/{id})
        Firebase-->>App: Return Driver Data
        alt Match Password && Has Assigned Vehicle
            App->>User: Grant Access (Driver Dashboard)
        else Error
            App->>User: Show Error (Invalid Password / No Vehicle)
        end
    end
```

### Live Tracking Flow
```mermaid
sequenceDiagram
    participant Driver
    participant DriverApp as Driver App
    participant GPS as Device GPS
    participant DB as Firebase Realtime DB
    participant UserApp as User App

    Driver->>DriverApp: Click "GO LIVE"
    loop Every 5 Seconds
        DriverApp->>GPS: Request Current Location
        GPS-->>DriverApp: Latitude & Longitude
        DriverApp->>DB: Update `vehicles/{vehicleId}/location`
    end
    
    UserApp->>DB: Subscribe to `vehicles/{vehicleId}/location`
    DB-->>UserApp: Real-time Location Updates
    UserApp->>UserApp: Render Vehicle Position & ETA
    
    Driver->>DriverApp: Click "STOP"
    DriverApp->>DB: Stop Updates
```

## ⚙️ Getting Started

### Prerequisites
- Flutter SDK (`>=3.3.1 <4.0.0`)
- Android Studio / VS Code
- Firebase Project configured and `google-services.json` / `GoogleService-Info.plist` added.

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/anupam9919/Real-Time-Vehicle-Tracking-System.git
   cd Real-Time-Vehicle-Tracking-System
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**
   Create a `.env` file in the root directory based on `.env.example`:
   ```env
   STUDENT_ID=your_student_id
   STUDENT_PASSWORD=your_student_password
   ADMIN_ID=your_admin_id
   ADMIN_PASSWORD=your_admin_password
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── core/                   # Shared utilities, theme, services, constants
│   ├── constants/          # Firebase path constants
│   ├── errors/             # Custom exceptions and failure classes
│   ├── services/           # Location service (GPS abstraction)
│   ├── theme/              # App colors and theme data
│   └── utils/              # Distance (Haversine) and ETA utilities
├── features/
│   ├── auth/               # Authentication (data → domain → presentation)
│   └── tracking/           # Vehicle tracking (data → domain → presentation)
├── routing/                # GoRouter configuration with auth guards
├── config/                 # Environment configuration
├── components/             # Shared UI widgets (Bus Stop finder)
├── adminPages/             # Admin screens (manage vehicles, drivers, boarding points)
├── driverPages/            # Driver dashboard with live GPS transmission
├── userPages/              # Student screens (home, track, search, account)
├── services/               # App-wide services (structured logger)
└── main.dart               # App entry point
```

---