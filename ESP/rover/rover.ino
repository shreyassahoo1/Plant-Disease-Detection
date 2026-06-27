#include <WiFi.h>
#include <WebServer.h>
#include <TinyGPS++.h>

const char* ssid = "Samarjeet23";
const char* password = "samyeet123";

WebServer server(80);

// GPS
TinyGPSPlus gps;
HardwareSerial GPSSerial(2);

// L298N Pins
#define ENA 15
#define IN1 12
#define IN2 18

#define ENB 26
#define IN3 14
#define IN4 27

void setSpeed() {
  analogWrite(ENA, 255);
  analogWrite(ENB, 255);
}

void stopMotors() {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);

  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}

void moveForward() {

  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);

  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
}

void moveBackward() {

  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);

  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, HIGH);
}

void turnLeft() {

  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);

  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
}

void turnRight() {

  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);

  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
}

void handleGPS() {

  String json = "{";

  if (gps.location.isValid()) {

    json += "\"latitude\":" + String(gps.location.lat(), 6) + ",";
    json += "\"longitude\":" + String(gps.location.lng(), 6) + ",";
    json += "\"satellites\":" + String(gps.satellites.value());

  } else {

    json += "\"latitude\":0,";
    json += "\"longitude\":0,";
    json += "\"satellites\":0";
  }

  json += "}";

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", json);
}

void handleRoot() {

  String page = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body{
font-family:Arial;
text-align:center;
margin-top:40px;
}
button{
width:120px;
height:60px;
font-size:20px;
margin:10px;
}
</style>
</head>
<body>

<h1>AgroNet Rover</h1>

<p>
<a href="/forward"><button>Forward</button></a>
</p>

<p>
<a href="/left"><button>Left</button></a>
<a href="/stop"><button>Stop</button></a>
<a href="/right"><button>Right</button></a>
</p>

<p>
<a href="/backward"><button>Backward</button></a>
</p>

<p>
<a href="/gps"><button>GPS Data</button></a>
</p>

</body>
</html>
)rawliteral";

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "text/html", page);
}

void setup() {

  Serial.begin(115200);

  GPSSerial.begin(9600, SERIAL_8N1, 16, 17);

  pinMode(ENA, OUTPUT);
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);

  pinMode(ENB, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

  setSpeed();
  stopMotors();

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

  server.on("/gps", handleGPS);

  server.on("/forward", []() {
    moveForward();
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.sendHeader("Location", "/");
    server.send(303);
  });

  server.on("/backward", []() {
    moveBackward();
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.sendHeader("Location", "/");
    server.send(303);
  });

  server.on("/left", []() {
    turnLeft();
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.sendHeader("Location", "/");
    server.send(303);
  });

  server.on("/right", []() {
    turnRight();
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.sendHeader("Location", "/");
    server.send(303);
  });

  server.on("/stop", []() {
    stopMotors();
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.sendHeader("Location", "/");
    server.send(303);
  });

  server.begin();

  Serial.println("Server Started");
}

void loop() {

  while (GPSSerial.available()) {
    gps.encode(GPSSerial.read());
  }

  if (gps.location.isUpdated()) {

    Serial.print("Latitude: ");
    Serial.println(gps.location.lat(), 6);

    Serial.print("Longitude: ");
    Serial.println(gps.location.lng(), 6);

    Serial.print("Satellites: ");
    Serial.println(gps.satellites.value());

    Serial.println("-------------------");
  }

  server.handleClient();
}