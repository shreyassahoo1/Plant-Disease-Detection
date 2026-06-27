/*
 * CameraWebServer.ino — RHYX M21-45 / non-OV2640 compatible
 *
 * This sensor does NOT support PIXFORMAT_JPEG natively.
 * We capture in PIXFORMAT_RGB565 and convert each frame to JPEG
 * using the ESP32's built-in frame2jpg() before streaming MJPEG
 * over HTTP on port 81 — compatible with the AgroNet AI web dashboard.
 */

#include <Arduino.h>
#include "esp_camera.h"
#include <WiFi.h>
#include <WebServer.h>
#include "img_converters.h"   // frame2jpg()

// ===========================
// Select camera model
// ===========================
#define CAMERA_MODEL_AI_THINKER
#include "camera_pins.h"

// ===========================
// WiFi credentials
// ===========================
const char *ssid     = "Samarjeet23";
const char *password = "samyeet123";

// Stream server on port 81
WebServer streamServer(81);

// ─── MJPEG stream handler ───────────────────────────────────────────────────
void handleStream() {
  WiFiClient client = streamServer.client();

  // Write raw HTTP headers directly to socket — WebServer.send() would close connection
  client.println("HTTP/1.1 200 OK");
  client.println("Access-Control-Allow-Origin: *");
  client.println("Content-Type: multipart/x-mixed-replace; boundary=frame");
  client.println("Connection: keep-alive");
  client.println("Cache-Control: no-cache");
  client.println();

  while (client.connected()) {
    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) {
      Serial.println("Camera capture failed");
      break;
    }

    uint8_t *jpgBuf = NULL;
    size_t   jpgLen = 0;
    bool     converted = frame2jpg(fb, 80, &jpgBuf, &jpgLen);
    esp_camera_fb_return(fb);

    if (!converted || jpgLen == 0) {
      Serial.println("JPEG conversion failed");
      break;
    }

    // Write MJPEG boundary + JPEG frame directly to socket
    client.printf("--frame\r\nContent-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n", jpgLen);
    client.write(jpgBuf, jpgLen);
    client.print("\r\n");
    free(jpgBuf);

    delay(50); // ~20 fps
  }
}

// ─── Single JPEG snapshot handler ───────────────────────────────────────────
void handleCapture() {
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    streamServer.send(500, "text/plain", "Camera capture failed");
    return;
  }

  uint8_t *jpgBuf = NULL;
  size_t   jpgLen = 0;
  bool converted = false;

  if (fb->format == PIXFORMAT_JPEG) {
    jpgBuf    = fb->buf;
    jpgLen    = fb->len;
  } else {
    converted = frame2jpg(fb, 80, &jpgBuf, &jpgLen);
    if (!converted) {
      esp_camera_fb_return(fb);
      streamServer.send(500, "text/plain", "JPEG conversion failed");
      return;
    }
  }

  streamServer.sendHeader("Access-Control-Allow-Origin", "*");
  streamServer.sendHeader("Content-Disposition", "inline; filename=capture.jpg");
  streamServer.send_P(200, "image/jpeg", (const char*)jpgBuf, jpgLen);

  if (converted) free(jpgBuf);
  esp_camera_fb_return(fb);
}

// ─── Root info page ─────────────────────────────────────────────────────────
void handleRoot() {
  String html = "<html><body style='font-family:Arial;text-align:center;margin-top:40px'>";
  html += "<h2>AgroNet ESP32-CAM</h2>";
  html += "<p><a href='/stream'>MJPEG Stream</a></p>";
  html += "<p><a href='/capture'>Single Snapshot</a></p>";
  html += "</body></html>";
  streamServer.sendHeader("Access-Control-Allow-Origin", "*");
  streamServer.send(200, "text/html", html);
}

// ─── Setup ──────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  Serial.setDebugOutput(true);
  Serial.println();

  // Camera config — RGB565, no PSRAM dependency
  camera_config_t config;
  config.ledc_channel  = LEDC_CHANNEL_0;
  config.ledc_timer    = LEDC_TIMER_0;
  config.pin_d0        = Y2_GPIO_NUM;
  config.pin_d1        = Y3_GPIO_NUM;
  config.pin_d2        = Y4_GPIO_NUM;
  config.pin_d3        = Y5_GPIO_NUM;
  config.pin_d4        = Y6_GPIO_NUM;
  config.pin_d5        = Y7_GPIO_NUM;
  config.pin_d6        = Y8_GPIO_NUM;
  config.pin_d7        = Y9_GPIO_NUM;
  config.pin_xclk      = XCLK_GPIO_NUM;
  config.pin_pclk      = PCLK_GPIO_NUM;
  config.pin_vsync     = VSYNC_GPIO_NUM;
  config.pin_href      = HREF_GPIO_NUM;
  config.pin_sccb_sda  = SIOD_GPIO_NUM;
  config.pin_sccb_scl  = SIOC_GPIO_NUM;
  config.pin_pwdn      = PWDN_GPIO_NUM;
  config.pin_reset     = RESET_GPIO_NUM;
  config.xclk_freq_hz  = 20000000;
  config.pixel_format  = PIXFORMAT_RGB565;  // RHYX M21-45 native format
  config.grab_mode     = CAMERA_GRAB_WHEN_EMPTY;
  config.jpeg_quality  = 12;
  config.fb_count      = 1;

  config.frame_size   = FRAMESIZE_QQVGA;   // 160x120 = 38KB — fits in DRAM
  config.fb_location  = CAMERA_FB_IN_DRAM; // force DRAM, skip PSRAM entirely

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed: 0x%x\n", err);
    return;
  }
  Serial.println("Camera init OK");

  // Connect WiFi
  WiFi.begin(ssid, password);
  WiFi.setSleep(false);
  Serial.print("WiFi connecting");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.println("WiFi connected");

  // Register routes
  streamServer.on("/",        handleRoot);
  streamServer.on("/stream",  handleStream);
  streamServer.on("/capture", handleCapture);
  streamServer.begin();

  Serial.print("Camera stream ready at http://");
  Serial.print(WiFi.localIP());
  Serial.println(":81/stream");
  Serial.print("Snapshot at http://");
  Serial.print(WiFi.localIP());
  Serial.println(":81/capture");
}

// ─── Loop ───────────────────────────────────────────────────────────────────
void loop() {
  streamServer.handleClient();
}