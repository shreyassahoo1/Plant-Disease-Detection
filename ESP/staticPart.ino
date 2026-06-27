#include <WiFi.h>
#include <WebServer.h>
#include <DHT.h>

// ======================
// WiFi Credentials
// ======================
const char* ssid = "Samarjeet23";
const char* password = "samyeet123";

// ======================
// Sensor Pins
// ======================
#define DHTPIN 4
#define DHTTYPE DHT11

#define SOIL_PIN 34
#define PH_PIN 35

DHT dht(DHTPIN, DHTTYPE);
WebServer server(80);

// Variables
float temperature = 0;
float humidity = 0;
int soilRaw = 0;
int phRaw = 0;
float phVoltage = 0;

// ======================
// Read Sensors
// ======================
void readSensors() {

  temperature = dht.readTemperature();
  humidity = dht.readHumidity();

  soilRaw = analogRead(SOIL_PIN);

  phRaw = analogRead(PH_PIN);
  phVoltage = phRaw * (3.3 / 4095.0);

  Serial.println("-----------------------");

  if (!isnan(temperature) && !isnan(humidity)) {
    Serial.print("Temperature: ");
    Serial.print(temperature);
    Serial.println(" °C");

    Serial.print("Humidity: ");
    Serial.print(humidity);
    Serial.println(" %");
  }

  Serial.print("Soil Moisture Raw: ");
  Serial.println(soilRaw);

  Serial.print("pH Raw: ");
  Serial.println(phRaw);

  Serial.print("pH Voltage: ");
  Serial.println(phVoltage);

  Serial.println("-----------------------");
}

// ======================
// API Route
// ======================
void handleSensors() {

  readSensors();

  String json = "{";
  json += "\"temperature\":" + String(temperature, 1) + ",";
  json += "\"humidity\":" + String(humidity, 1) + ",";
  json += "\"soil\":" + String(soilRaw) + ",";
  json += "\"ph_raw\":" + String(phRaw) + ",";
  json += "\"ph_voltage\":" + String(phVoltage, 2);
  json += "}";

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", json);
}

// ======================
// Root Page
// ======================
void handleRoot() {

  String html = R"rawliteral(
  <html>
  <head>
  <meta http-equiv="refresh" content="5">
  <title>Static ESP32 Sensor Node</title>
  </head>
  <body>
    <h2>Static ESP32 Sensor Data</h2>
    <p>Open <b>/sensors</b> for JSON data</p>
  </body>
  </html>
  )rawliteral";

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "text/html", html);
}

// ======================
// Setup
// ======================
void setup() {

  Serial.begin(115200);

  dht.begin();

  WiFi.begin(ssid, password);

  Serial.print("Connecting");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("WiFi Connected");

  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  server.on("/", handleRoot);
  server.on("/sensors", handleSensors);

  server.begin();

  Serial.println("Web Server Started");
}

// ======================
// Loop
// ======================
void loop() {
  server.handleClient();
}