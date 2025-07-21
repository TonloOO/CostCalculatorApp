# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI-based iOS cost calculator app for textile/fabric manufacturing calculations. The app helps calculate yarn costs, labor costs, and other production expenses in textile manufacturing. The interface is primarily in Chinese, serving Chinese-speaking textile industry users.

## Development Commands

### Building and Testing
- Open the project in Xcode: `open CostCalculatorApp.xcodeproj`
- Build: Use Xcode's Product → Build (⌘+B)
- Run tests: Use Xcode's Product → Test (⌘+U)
- Run the app: Use Xcode's Product → Run (⌘+R)

### Test Structure
- Unit tests: `CostCalculatorAppTests/CostCalculatorAppTests.swift`
- UI tests: `CostCalculatorAppUITests/`

## Architecture

### App Structure
- **Main App**: `CostCalculatorApp.swift` - Entry point with Core Data integration
- **Navigation**: Tab-based navigation with 4 main sections:
  - Home (费用计算): Cost calculation features
  - Chat (织梦·雅集): Chat functionality with API integration
  - Statistics (统计): Data analysis and statistics
  - Settings (设置): App configuration

### Core Models
- **Calculator.swift**: Main calculation engine for textile cost calculations
- **Material.swift**: Defines material properties and yarn types
- **CalculationResults.swift**: Stores calculation outputs
- **PersistenceController.swift**: Core Data + CloudKit integration

### Data Persistence
- Uses Core Data with CloudKit synchronization
- CloudKit container: `iCloud.ton.CostCalculatorApp`
- Model file: `Model.xcdatamodeld/Model.xcdatamodel/`

### Key Views
- **Calculator Views**: Located in `Views/Calculator/`
  - `CostCalculatorView.swift`: Single material calculator
  - `CostCalculatorViewWithMaterial.swift`: Multi-material calculator
  - `CalculationHomeView.swift`: Main calculator landing page
- **Chat Views**: Located in `Views/Chat/`
  - Integrates with external API at `https://zscy.space/api/v1/sse`

### Calculation Logic
The core calculation engine (`Calculator.swift`) performs textile manufacturing cost calculations including:
- Warp and weft yarn weight/cost calculations
- Labor cost based on machine speed and efficiency
- Material ratio handling for multi-material fabrics
- Input validation with Chinese error messages

### External Dependencies
- **MarkdownUI**: For rendering markdown content in chat
- **Core Data + CloudKit**: For data persistence and sync
- **External Chat API**: Custom API for chat functionality

## Development Notes

### Code Style
- Uses SwiftUI for all UI components
- Chinese language interface and error messages
- Follows iOS/SwiftUI conventions
- Core Data models for persistent storage

### Key Constants
- Default D value and calculation constants in `CalculationConstants.swift`
- Haptic feedback integration via `HapticFeedbackManager.swift`

### Chat Integration
- External API service for chat functionality
- User management through `UserManager.swift`
- SSE (Server-Sent Events) support for real-time messaging