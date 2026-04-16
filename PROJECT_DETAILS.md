# Plant Disease Detection - Comprehensive Project Documentation

## 📋 Executive Summary

**Plant Doctor** is an AI and IoT-based mobile application that leverages machine learning and artificial intelligence to detect plant diseases through image analysis. The application uses **TensorFlow Lite** for on-device inference and **Google Gemini AI** for intelligent disease analysis and treatment recommendations. Users can capture or upload plant images, receive instant disease diagnoses with confidence scores, and access cure/care steps.

---

## 🎯 Project Overview

| Property | Value |
|----------|-------|
| **Project Name** | Plant-Disease-Detection / Plant Doctor |
| **Type** | Cross-platform Mobile Application |
| **Framework** | Flutter |
| **Language** | Dart |
| **Version** | 1.0.0+1 |
| **Minimum SDK** | Dart 3.10.1+ |
| **Supported Platforms** | Android, iOS, Web, Linux, macOS, Windows |
| **Publication Status** | Private (Not published to pub.dev) |

---

## 🎨 Features & Functionality

### 1. **Splash Screen**
- Application entry point
- Brand/app introduction
- Navigation to home screen

### 2. **Home Screen**
- **Main UI Hub** - Central navigation point for all features
- **Quick Action Cards**:
  - "Take a Picture" - Opens device camera for real-time plant capture
  - "Load from Gallery" - Import plant images from device storage
- **History Access** - Quick navigation to view past scan results
- **Material Design UI** - Modern, user-friendly interface with green-themed styling

### 3. **Camera & Preview System**
#### Camera Screen
- Real-time camera preview
- Capture button to take images
- Flash support
- Optimized for plant photography

#### Preview Screen
- Full image preview before analysis
- **Advanced Image Cropping**:
  - Drag and crop specific plant portions
  - Supports custom aspect ratios
  - Platform-specific UI (Android native, iOS native, Web)
- **Image Analysis Trigger**:
  - Processes image through AI models
  - Shows loading indicator during analysis
  - Handles errors gracefully

### 4. **Disease Analysis & Results**
#### Result Screen
- **Disease Information**:
  - Plant species identification
  - Disease name/health status
  - Confidence score (0.0 - 1.0)
- **Treatment Recommendations**:
  - Step-by-step cure/care instructions
  - Nutritional advice if plant is healthy
  - Actionable prevention tips
- **Visual Feedback**:
  - Disease severity indicators
  - Confidence percentage display
  - Plant image thumbnail
- **Automatic History Saving**:
  - Records timestamp, image, disease, confidence
  - Enables future reference and tracking

### 5. **Scan History**
- **Database-Backed Storage**:
  - All previous scan results stored locally
  - Searchable and sortable by date
- **History Features**:
  - View past diagnoses
  - Delete old records
  - Re-examine saved plant images
  - Track disease progression over time
- **Data Persistence**:
  - SQLite database on device
  - No cloud dependency

### 6. **Theme & Styling**
- **App Theme** - Consistent green/teal color scheme (plant-themed)
- **Material Design 3** - Modern Flutter design system
- **No Debug Banner** - Professional appearance

---

## 🏗️ Project Architecture

### Directory Structure

```
Plant-Disease-Detection/
├── lib/                              # Flutter application source code
│   ├── main.dart                     # Entry point (MyApp widget)
│   ├── core/                         # Core application utilities
│   │   ├── db/
│   │   │   └── database_helper.dart  # SQLite database management
│   │   ├── services/                 # Business logic services
│   │   │   ├── tflite_service.dart   # TensorFlow Lite model inference
│   │   │   ├── gemini_service.dart   # Google Gemini AI integration
│   │   │   ├── disease_service.dart  # Mock disease analysis (fallback)
│   │   │   └── instructions.txt      # API setup guidance
│   │   └── theme/
│   │       └── app_theme.dart        # Material theme configuration
│   └── features/                     # Feature modules (screens)
│       ├── splash/
│       │   └── splash_screen.dart    # App launch screen
│       ├── home/
│       │   └── home_screen.dart      # Main navigation hub
│       ├── scan/
│       │   ├── camera_screen.dart    # Camera capture interface
│       │   └── preview_screen.dart   # Image preview & cropping
│       ├── results/
│       │   └── result_screen.dart    # Analysis results display
│       └── history/
│           └── history_screen.dart   # Past scans database view
├── assets/
│   └── models/
│       ├── plant_disease_model.tflite  # ML model (uncompressed: 1-100MB)
│       └── labels.txt                  # Disease class labels
├── android/                          # Android-specific configuration
│   ├── app/
│   │   ├── build.gradle.kts          # Gradle build configuration
│   │   ├── proguard-rules.pro         # Code obfuscation rules
│   │   └── src/
│   │       └── main/                 # Android manifest & resources
│   ├── build.gradle.kts
│   ├── gradle.properties
│   └── settings.gradle.kts
├── ios/                              # iOS-specific configuration
│   ├── Runner/
│   │   ├── Info.plist                # iOS app configuration
│   │   ├── AppDelegate.swift         # iOS app lifecycle
│   │   ├── Runner-Bridging-Header.h  # Objective-C bridge
│   │   └── Assets.xcassets/          # iOS app icons & images
│   ├── Runner.xcodeproj/
│   ├── Runner.xcworkspace/
│   └── RunnerTests/
├── web/                              # Web deployment files
│   ├── index.html                    # Web entry point
│   ├── manifest.json                 # PWA manifest
│   └── icons/                        # Web app icons
├── windows/                          # Windows desktop build
├── macos/                            # macOS desktop build
├── linux/                            # Linux desktop build
├── test/
│   └── widget_test.dart              # Flutter widget tests
├── pubspec.yaml                      # Package dependencies & configuration
├── analysis_options.yaml             # Dart linter rules
└── README.md                         # Basic project readme
```

---

## 🧮 Core Services & Components

### 1. **TFLiteService** (`lib/core/services/tflite_service.dart`)

**Purpose**: Local device-based plant disease classification using TensorFlow Lite

**Key Methods**:
- `loadModel()` - Loads `.tflite` model and labels from assets
- `predict(File imageFile)` - Runs inference on plant images

**Processing Pipeline**:
```
Input Image
    ↓
Image Decoding (JPEG/PNG)
    ↓
Resizing (224×224 pixels)
    ↓
Normalization ([-1, 1] range)
    ↓
Tensor Conversion [1, 224, 224, 3]
    ↓
Model Inference
    ↓
Output Processing (Softmax)
    ↓
Label Mapping & Confidence Scores
    ↓
Results List<Map<String, dynamic>>
```

**Output Format**:
```dart
[
  {
    'label': 'Tomato Early Blight',
    'confidence': 0.95
  },
  {
    'label': 'Leaf Mold',
    'confidence': 0.03
  }
  // ... more predictions
]
```

**Model Details**:
- **Input Shape**: [1, 224, 224, 3] (batch_size, height, width, rgb_channels)
- **Output Shape**: [1, num_classes] (typically 38 disease classes)
- **Normalization**: [-1, 1] range (pixel - 127.5) / 127.5
- **Format**: `.tflite` (optimized for mobile devices)
- **Location**: `assets/models/plant_disease_model.tflite`

---

### 2. **GeminiService** (`lib/core/services/gemini_service.dart`)

**Purpose**: AI-powered plant analysis using Google's Gemini 2.5 Flash model

**Key Methods**:
- `analyzePlant(File imageFile)` - Sends image to Gemini for intelligent analysis

**Capabilities**:
- Plant species identification
- Disease detection with names
- Confidence scoring
- Health status determination
- Treatment recommendations
- Care instructions for healthy plants

**API Integration**:
- **Model**: `gemini-2.5-flash`
- **Endpoint**: Google AI API (Cloud-based)
- **Authentication**: API Key (requires setup in code)
- **Format**: Multi-part content (text prompt + image bytes)

**Analysis Prompt**:
```
"Analyze this plant image. Identify the plant and detect any diseases. 
Return the result purely as a JSON object with the following structure: 
{ "plant_name": "Name of plant", "disease_name": "Name of disease or Healthy", 
"confidence": 0.95, "is_healthy": true/false, 
"cure_steps": ["Step 1", "Step 2", "Step 3"] } 
If healthy, provide care tips in cure_steps. 
Do not include markdown formatting like ```json ... ```, just the raw JSON string."
```

**Response Format**:
```json
{
  "plant_name": "Tomato",
  "disease_name": "Early Blight",
  "confidence": 0.92,
  "is_healthy": false,
  "cure_steps": [
    "Remove infected leaves",
    "Apply fungicide spray",
    "Ensure proper drainage",
    "Increase spacing between plants"
  ]
}
```

**Setup Required**:
⚠️ API key must be added to `_apiKey` variable in `GeminiService()`

---

### 3. **DatabaseHelper** (`lib/core/db/database_helper.dart`)

**Purpose**: Local SQLite database for persistent storage of scan history

**Database Schema**:
```sql
CREATE TABLE history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  imagePath TEXT NOT NULL,
  diseaseName TEXT NOT NULL,
  confidence REAL NOT NULL,
  date TEXT NOT NULL
)
```

**Key Methods**:
- `database` - Singleton getter for database instance
- `_initDB(String filePath)` - Initializes database connection
- `_createDB(Database db, int version)` - Creates schema on first run
- `create(Map<String, dynamic> row)` - Inserts scan record
- `readAllHistory()` - Retrieves all scans (ordered by date DESC)
- `delete(int id)` - Removes a scan record

**Database File**: `plant_history.db` (stored in app-specific documents folder)

**Record Example**:
```
id: 1
imagePath: "/data/user/0/com.example.plant_app/cache/IMG_123.jpg"
diseaseName: "Tomato Early Blight"
confidence: 0.95
date: "Nov 15, 2024, 2:30 PM"
```

---

### 4. **DiseaseService** (`lib/core/services/disease_service.dart`)

**Purpose**: Fallback mock disease analysis service for testing/development

**Status**: Currently unused in production flow (replaced by Gemini)

**Mock Data**:
- Tomato Early Blight (98% confidence)
- Tomato Late Blight (85% confidence)
- Healthy (99% confidence)
- Leaf Mold (75% confidence)

---

## 📦 Dependencies & Libraries

### Core Framework
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Mobile UI framework |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

### Camera & Image Processing
| Package | Version | Purpose |
|---------|---------|---------|
| `camera` | ^0.11.3 | Device camera access |
| `image_picker` | ^1.2.1 | Gallery image selection |
| `image_cropper` | ^11.0.0 | Advanced image cropping |
| `image` | ^4.7.2 | Image processing & manipulation |

### Machine Learning
| Package | Version | Purpose |
|---------|---------|---------|
| `tflite_flutter` | ^0.12.1 | TensorFlow Lite inference |
| `google_generative_ai` | ^0.4.7 | Google Gemini AI API |

### Database & Storage
| Package | Version | Purpose |
|---------|---------|---------|
| `sqflite` | ^2.4.2 | SQLite database |
| `path_provider` | ^2.1.5 | App data directory paths |
| `path` | ^1.9.1 | File path utilities |

### Utilities
| Package | Version | Purpose |
|---------|---------|---------|
| `intl` | ^0.20.2 | Internationalization & date formatting |
| `http` | ^1.6.0 | HTTP requests (indirect dependency) |
| `uuid` | ^4.5.2 | Unique identifier generation |

### Development
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_test` | SDK | Widget testing framework |
| `flutter_lints` | ^6.0.0 | Dart/Flutter code style rules |

---

## 🔧 Platform Configuration

### Android Configuration

**Target Specifications** (`android/app/build.gradle.kts`):
```
Namespace: com.example.plant_app
Compile SDK: Latest Flutter SDK (35+)
Target SDK: Latest Flutter SDK
Min SDK: 21+ (Android 5.0)
JVM Target: Java 17
NDK Version: Latest Flutter NDK
```

**Key Configuration**:
```gradle
aaptOptions {
    noCompress("tflite")  // TFLite models must not be compressed
}
```

**Build Features**:
- **Release Build**: 
  - Code shrinking enabled (minified)
  - Resource shrinking enabled
  - ProGuard obfuscation rules applied
  - Debug signing config

**Permissions** (defined in `AndroidManifest.xml`):
- Camera access
- File read/write
- Internet access (for Gemini API)

---

### iOS Configuration

**Target Specifications** (`ios/Runner/Info.plist`):
```
Bundle Display Name: Plant App
Bundle Identifier: com.example.plant_app (configurable)
Minimum iOS Version: 11.0+
```

**Supported Orientations**:
- Portrait (primary)
- Landscape Left
- Landscape Right
- iPad: All orientations

**Required Permissions**:
- Camera access
- Photo library access
- Internet access

---

### Web Configuration

**Entry Point**: `web/index.html`
- Progressive Web App (PWA) capable
- Service worker support
- Offline functionality possible

**Manifest**: `web/manifest.json` - PWA metadata

---

### Desktop Platforms

**Windows**: CMake-based build system
**macOS**: Xcode workspace
**Linux**: CMake-based build system

---

## 🎬 Application Flow & User Journey

### Complete Workflow

```
┌─────────────────┐
│  Splash Screen  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Home Screen    │
└────────┬────────┘
         │
    ┌────┴────┐
    │          │
    ▼          ▼
┌──────────┐  ┌──────────┐
│ Camera   │  │ Gallery  │
│ Screen   │  │ Picker   │
└────┬─────┘  └────┬─────┘
     │            │
     └────┬───────┘
          │
          ▼
┌──────────────────┐
│ Preview Screen   │
│ - Crop Image     │
│ - Analyze Button │
└────────┬─────────┘
         │
         ▼
    ┌────────────────┐
    │ Image Analysis │
    │ via Gemini API │
    └────────┬───────┘
             │
             ▼
    ┌────────────────┐
    │ Parse JSON     │
    │ Response       │
    └────────┬───────┘
             │
             ▼
┌──────────────────────┐
│ Result Screen        │
│ - Disease Info       │
│ - Confidence Score   │
│ - Treatment Steps    │
│ [Auto-save to DB]    │
└────────┬─────────────┘
         │
    ┌────┴────┐
    │          │
    ▼          ▼
┌────────┐  ┌──────────┐
│ Home   │  │ History  │
│ Screen │  │ Screen   │
└────────┘  └──────────┘
```

### Detailed Steps

**1. Launch Application**
- Flutter engine initializes
- Splash screen displays
- Main app theme loads

**2. Home Screen**
- User sees three options:
  - "Take a Picture" → Camera
  - "Load from Gallery" → Image Picker
  - "View Scan History" → Database Browse

**3. Image Capture/Selection**
- **Camera**: Real-time preview, capture, confirmation
- **Gallery**: File browser, thumbnail selection

**4. Image Preview & Preprocessing**
- Full image preview displayed
- User can crop/adjust image
- Optimization before analysis

**5. AI Analysis**
- Image sent to Gemini API
- Processing (2-5 seconds typical)
- JSON response parsed

**6. Results Display**
- Plant species shown
- Disease name/health status
- Confidence percentage
- Treatment/care recommendations
- Image thumbnail

**7. Automatic History Save**
- Data inserted to SQLite
- Background operation (no UI blocking)

**8. History Access**
- Browse all past scans
- Click to view details
- Delete option per record

---

## 🔐 Security & Privacy

### Data Security
- **Local Storage**: All history stored on-device (no cloud sync)
- **Image Handling**: Images processed and discarded (not cached permanently by default)
- **API Communication**: Gemini API uses HTTPS encryption
- **Permissions**: Explicit camera/photo permissions requested

### Privacy Considerations
- No user tracking/analytics enabled
- No personal data collection
- No third-party ad networks
- Local database only (SQLite)

### Sensitive Configuration
⚠️ **API Key Management**:
- Gemini API key hardcoded in source (must be removed before shipping)
- **Recommendation**: Use environment variables or secure backend
- Never commit API keys to public repositories

---

## 🚀 Building & Deployment

### Development Setup

**Prerequisites**:
```bash
Flutter 3.10.1+
Dart 3.10.1+
Android Studio (for Android development)
Xcode (for iOS development)
```

**Project Setup**:
```bash
flutter pub get              # Install dependencies
flutter pub upgrade          # Update to latest versions
flutter analyze              # Check code quality
flutter test                 # Run unit tests
```

### Building for Platforms

**Android**:
```bash
flutter build apk               # Debug APK
flutter build apk --release     # Release APK
flutter build appbundle         # Google Play AAB
```

**iOS**:
```bash
flutter build ios               # Debug build
flutter build ios --release     # Release build (IPA)
```

**Web**:
```bash
flutter build web               # Static web files
flutter run -d chrome           # Run in Chrome
```

**Desktop**:
```bash
flutter build windows           # Windows executable
flutter build macos             # macOS app bundle
flutter build linux             # Linux AppImage/binary
```

### Release Configuration

**Android Release**:
- Signing configuration required
- ProGuard rules: `android/app/proguard-rules.pro`
- Version: 1.0.0 (configurable in `pubspec.yaml`)

**iOS Release**:
- Apple Developer certificate required
- Bundle identifier: `com.example.plant_app`
- Team ID setup in Xcode

---

## 📊 Performance Considerations

### Model Performance
- **TFLite Model**: ~10-50MB (optimized for mobile)
- **Inference Time**: 
  - Device inference: 100-500ms (depending on device)
  - Gemini API: 2-5 seconds (network-dependent)
- **Memory Usage**: ~150-300MB during operation

### Optimization
- **Image Preprocessing**: 224×224 resize (standard CNN input size)
- **Batch Size**: 1 (single image inference)
- **Quantization**: Model pre-quantized (int8 typically)
- **Lazy Loading**: Model loaded on first prediction

---

## 🐛 Troubleshooting & Known Issues

### Common Issues

**1. Model Loading Fails**
- **Cause**: Model file missing from assets
- **Solution**: Ensure `pubspec.yaml` includes `assets/models/` directory

**2. Gemini API Errors**
- **Cause**: Invalid/missing API key
- **Solution**: Add valid API key to `GeminiService._apiKey`

**3. Camera Permission Denied**
- **Cause**: Permissions not granted
- **Solution**: Grant camera permission when prompted

**4. Database Locked**
- **Cause**: Concurrent access
- **Solution**: Ensure single database instance (singleton pattern used)

**5. Image Cropper Issues**
- **Cause**: Platform-specific UI not implemented
- **Solution**: Web platform may need fallback implementation

---

## 📝 Code Quality & Standards

### Linting Rules
- **Framework**: `flutter_lints`
- **Configuration**: `analysis_options.yaml`
- **Recommendations**: 
  - Follow Dart naming conventions
  - Avoid print statements (use logging)
  - Type all variables explicitly

### Testing
- **Test Framework**: `flutter_test`
- **Location**: `test/widget_test.dart`
- **Coverage**: Widget testing for UI components

---

## 🔄 Future Enhancement Opportunities

1. **Offline Gemini**: Edge-based AI analysis without API calls
2. **Real-time Camera Preview**: Live disease detection in camera feed
3. **Multi-language Support**: Internationalization (i18n)
4. **Advanced Filtering**: Filter history by disease, date range, confidence
5. **Export Reports**: PDF/CSV export of scan history
6. **Image Upload**: Share results with agronomists
7. **Crop Management**: Track multiple plants/garden plots
8. **Weather Integration**: Add weather data to recommendations
9. **Push Notifications**: Alerts for seasonal diseases
10. **Offline Mode**: Download latest model for offline use

---

## 📚 Additional Resources

### Model Asset
- **File**: `assets/models/plant_disease_model.tflite`
- **Labels**: `assets/models/labels.txt`
- **Format**: TensorFlow Lite quantized model
- **Input**: 224×224 RGB images
- **Output**: 38-class disease classification

### API Documentation
- **Gemini API**: https://ai.google.dev/
- **TFLite Docs**: https://www.tensorflow.org/lite/
- **Flutter Docs**: https://flutter.dev/

### Dependencies Documentation
- Camera: https://pub.dev/packages/camera
- Image Picker: https://pub.dev/packages/image_picker
- SQLite (sqflite): https://pub.dev/packages/sqflite
- TFLite Flutter: https://pub.dev/packages/tflite_flutter

---

## 📄 Project Metadata

```yaml
Project: Plant Disease Detection (Plant Doctor)
Version: 1.0.0+1
Type: Cross-Platform Mobile App
Framework: Flutter 3.10.1+
Language: Dart
Database: SQLite (sqflite)
ML Models: TensorFlow Lite, Google Gemini
Platforms: Android, iOS, Web, Windows, macOS, Linux
License: Private/Proprietary
Author: [Project Developer]
Created: [Development Start Date]
```

---

## 🎓 Key Architecture Decisions

### 1. **Dual AI Approach**
- **TFLite**: Fast, offline-capable local inference
- **Gemini**: Powerful, detailed analysis with cure recommendations
- **Benefit**: Flexibility to switch between models based on user preference

### 2. **Singleton Database Pattern**
```dart
static final DatabaseHelper instance = DatabaseHelper._init();
```
- Ensures only one database connection
- Prevents concurrency issues
- Efficient resource management

### 3. **Feature-Based Architecture**
- Screens organized by user-facing features
- Core services separated from UI
- Easy to maintain and extend

### 4. **Local-First Approach**
- History stored on-device (privacy-focused)
- No mandatory cloud account
- Works offline for previously cached analyses

---

## 📌 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0+1 | TBD | Initial release |

---

**Generated**: April 16, 2026

This document provides a complete technical overview of the Plant Disease Detection application, including architecture, features, dependencies, configuration, and operational details. For implementation questions, refer to the individual source files and inline code documentation.
