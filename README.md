# 🌱 AgriWatch
### IoT-Based Smart Agriculture Monitoring & Disease Detection System

![GitHub](https://img.shields.io/badge/Platform-ESP32-blue)
![Language](https://img.shields.io/badge/Language-C%2B%2B-orange)
![Frontend](https://img.shields.io/badge/Frontend-HTML%20%7C%20CSS%20%7C%20JavaScript-green)
![Backend](https://img.shields.io/badge/Backend-Python-yellow)
![License](https://img.shields.io/badge/License-MIT-success)

An IoT-powered smart agriculture system that combines **real-time environmental monitoring**, **rover-based crop inspection**, **live video streaming**, and **AI-powered disease detection** to assist farmers in monitoring crop health efficiently.

---

# Overview

AgriWatch consists of two independent yet interconnected modules:

## Static Monitoring Unit

The static unit continuously monitors environmental and soil parameters using multiple sensors connected to an ESP32. The collected data is transmitted over Wi-Fi to a web dashboard for real-time monitoring.

Monitored parameters include:

- 🌡 Temperature
- 💧 Humidity
- 🌱 Soil Moisture
- 🧪 Soil pH

---

## Dynamic Rover Unit

The rover allows farmers to remotely inspect crops using a browser.

It provides:

- Remote navigation
- Live ESP32-CAM video streaming
- GPS location
- Image capture
- AI-based disease detection

---

# Features

## Static Unit

- Real-time Temperature Monitoring
- Humidity Monitoring
- Soil Moisture Monitoring
- Soil pH Monitoring
- ESP32 Wi-Fi Communication
- Browser Dashboard

---

## Dynamic Rover

- Remote Rover Control
- ESP32-CAM Live Streaming
- GPS Tracking
- AI Disease Detection
- Image Capture
- Browser-based Controls
- Forward / Reverse / Left / Right Motion

---

# System Architecture

```
                     +----------------------+
                     |   Web Dashboard      |
                     +----------+-----------+
                                |
                          Wi-Fi Network
                                |
         ------------------------------------------
         |                                        |
         |                                        |
+--------v--------+                    +----------v---------+
| Static ESP32    |                    | Rover ESP32        |
|                 |                    |                    |
| DHT11           |                    | L298N Driver       |
| Soil Moisture   |                    | GPS Module         |
| Soil pH         |                    | ESP32-CAM          |
+--------+--------+                    +----------+---------+
         |                                        |
         |                                        |
         |                              Live Video Stream
         |                                        |
         +-------------------+--------------------+
                             |
                       AI Disease Detection
```

---

# Project Architecture

```
                  AgriWatch
                      |
      --------------------------------
      |                              |
 Static Monitoring Unit        Dynamic Rover
      |                              |
+-----+-----+                 +------+------+
| DHT11     |                 | ESP32-CAM   |
| Soil      |                 | GPS         |
| pH        |                 | L298N       |
| ESP32     |                 | ESP32       |
+-----------+                 +-------------+
        \                          /
         \                        /
          \                      /
           ------ Dashboard -----
                    |
             Disease Detection
```

---

# Hardware Requirements

## Static Unit

- ESP32 Development Board
- DHT11 Sensor
- Soil Moisture Sensor
- Soil pH Sensor
- Breadboard
- Jumper Wires

---

## Rover Unit

- ESP32 Development Board
- ESP32-CAM
- L298N Motor Driver
- GPS Module
- 4WD Rover Chassis
- DC Motors
- Battery Pack

---

# Software Requirements

- Arduino IDE 2.x
- ESP32 Board Package
- Python 3.x
- Flask
- HTML
- CSS
- JavaScript
- Git

---

# Folder Structure

```
AgriWatch/
│
├── Static_Unit/
│   └── Static_ESP32.ino
│
├── Rover_Unit/
│   ├── Rover_Control.ino
│   └── ESP32_CAM/
│
├── Dashboard/
│   ├── index.html
│   ├── style.css
│   └── script.js
│
├── AI_Model/
│   ├── app.py
│   ├── model/
│   └── uploads/
│
├── Images/
│
├── README.md
└── LICENSE
```

---

# Hardware Connections

## Static ESP32

| Sensor | GPIO |
|---------|------|
| DHT11 | 4 |
| Soil Moisture | 34 |
| Soil pH | 35 |

---

## Rover ESP32

| Pin | GPIO |
|------|------|
| ENA | 15 |
| IN1 | 12 |
| IN2 | 18 |
| ENB | 26 |
| IN3 | 14 |
| IN4 | 27 |

---

## GPS

| GPS | ESP32 |
|------|-------|
| TX | RX2 |
| RX | TX2 |
| VCC | 3.3V |
| GND | GND |

---

# ESP32 Setup

## 1. Install Arduino IDE

Download:

https://www.arduino.cc/en/software

---

## 2. Install ESP32 Boards

Go to

```
File → Preferences
```

Add

```
https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
```

Then

```
Tools
→ Board
→ Boards Manager
```

Search

```
ESP32
```

Install

```
Espressif Systems ESP32
```

---

# Installation

Clone the repository

```bash
git clone https://github.com/yourusername/AgriWatch.git
```

Go to the project

```bash
cd AgriWatch
```

Install Python dependencies

```bash
pip install -r requirements.txt
```

---

# Configure Wi-Fi

Inside both ESP32 sketches

```cpp
const char* ssid = "YOUR_WIFI";
const char* password = "YOUR_PASSWORD";
```

---

# Upload the Code

### Static Unit

- Select ESP32 Board
- Select COM Port
- Upload Static_ESP32.ino

---

### Rover Unit

- Upload Rover_Control.ino

---

### ESP32-CAM

Upload CameraWebServer or your custom camera sketch.

---

# Running the Project

1. Power the Static ESP32
2. Power the Rover
3. Start the AI Server

```bash
python app.py
```

4. Open Dashboard

```
Dashboard/index.html
```

Update the IP addresses if required.

---

# AI Disease Detection

Create a virtual environment

```bash
python -m venv venv
```

Activate

Windows

```bash
venv\Scripts\activate
```

Linux

```bash
source venv/bin/activate
```

Install packages

```bash
pip install -r requirements.txt
```

Run

```bash
python app.py
```

---

# Workflow

```
Farmer
   │
   ▼
Dashboard
   │
   ├────────► Static ESP32
   │             │
   │             ▼
   │      Sensor Data
   │
   ├────────► Rover ESP32
   │             │
   │             ▼
   │      Rover Navigation
   │
   ├────────► ESP32-CAM
   │             │
   │             ▼
   │      Live Video
   │
   └────────► AI Server
                 │
                 ▼
         Disease Prediction
```

---

# Future Improvements

- Autonomous Navigation
- Automatic Irrigation
- Fertilizer Recommendation
- Cloud Database
- Mobile Application
- LoRa Communication
- Solar Power Integration
- Multi-node Deployment

---

# Tech Stack

| Category | Technology |
|-----------|------------|
| Hardware | ESP32, ESP32-CAM, GPS, DHT11, Soil Moisture, pH Sensor |
| Embedded | Arduino C++ |
| Frontend | HTML, CSS, JavaScript |
| Backend | Python, Flask |
| AI | TensorFlow / Keras |
| Communication | Wi-Fi |
| Version Control | Git & GitHub |

---

# Contributing

Contributions are welcome!

1. Fork the repository
2. Create a new branch
3. Commit your changes
4. Push your branch
5. Open a Pull Request

---

# License

This project is licensed. 

---

# Acknowledgements

- Espressif Systems
- Arduino Community
- TensorFlow
- OpenCV
- Open Source IoT Community

---
