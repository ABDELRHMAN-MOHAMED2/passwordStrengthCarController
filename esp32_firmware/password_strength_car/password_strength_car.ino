#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <BluetoothSerial.h>
#include <string.h>

#if __has_include(<esp_arduino_version.h>)
#include <esp_arduino_version.h>
#endif

#ifndef ESP_ARDUINO_VERSION_MAJOR
#define ESP_ARDUINO_VERSION_MAJOR 2
#endif

BluetoothSerial SerialBT;
WiFiClientSecure secureClient;

// ===== WIFI SETTINGS =====
// Leave these placeholders unchanged if you only want to use the Flutter
// Bluetooth app. Fill them in to enable WiFi/API control.
const char *ssid = "your_wifi_name";
const char *password = "your_wifi_password";

// ===== API SETTINGS =====
const char *baseUrl = "https://robodrive.runasp.net";
const char *loginEndpoint = "/api/auth/login";
const char *carEmail = "your_email@example.com";
const char *carPassword = "your_password";
String carId = "your_car_id";

String jwtToken = "";
String lastApiCommand = "";
int lastApiSpeed = -1;

// ===== BLUETOOTH SETTINGS =====
const char *DEVICE_NAME = "ESP32_PASSWORD_CAR";

// ===== MOTOR PINS =====
// Matches the wiring photo:
// L298N IN1 -> ESP32 GPIO 27
// L298N IN2 -> ESP32 GPIO 26
// L298N ENA -> ESP32 GPIO 14
// L298N IN3 -> ESP32 GPIO 25
// L298N IN4 -> ESP32 GPIO 33
// L298N ENB -> ESP32 GPIO 12
#define IN1 27
#define IN2 26
#define IN3 25
#define IN4 33
#define ENA 14
#define ENB 12

#define PWM_FREQ 1000
#define PWM_RES 8
#define LEFT_PWM_CHANNEL 0
#define RIGHT_PWM_CHANNEL 1

const int DEFAULT_SPEED = 220;
const unsigned long API_POLL_INTERVAL_MS = 350;
const unsigned long WIFI_RECONNECT_INTERVAL_MS = 8000;
const unsigned long LOGIN_RETRY_INTERVAL_MS = 5000;

unsigned long lastApiPollAt = 0;
unsigned long lastWifiReconnectAt = 0;
unsigned long lastLoginAttemptAt = 0;
unsigned long timedStopAt = 0;
String pendingTimedDoneMessage = "";

void setupMotors();
void setupBluetooth();
void setupWifiApi();
void connectWifi();
bool wifiApiConfigured();
bool ensureToken();
bool fetchToken();
void getLastCommand();
void handleBluetooth();
void handleBluetoothCommand(char command);
void runTimedCommand(String command, int speed, unsigned long durationMs, const char *doneMessage);
void controlCar(String command, int speed);
void stopCar();
void forward(int speed);
void backward(int speed);
void left(int speed);
void right(int speed);
void setMotorSpeed(int leftSpeed, int rightSpeed);
void writePwm(int leftSpeed, int rightSpeed);

void setup() {
  Serial.begin(115200);
  setupMotors();
  setupBluetooth();
  setupWifiApi();

  Serial.println("ESP32 Password Strength Car is ready");
}

void loop() {
  handleBluetooth();

  if (timedStopAt > 0 && millis() >= timedStopAt) {
    timedStopAt = 0;
    stopCar();
    if (pendingTimedDoneMessage.length() > 0) {
      SerialBT.println(pendingTimedDoneMessage);
      pendingTimedDoneMessage = "";
    }
  }

  if (!wifiApiConfigured()) {
    return;
  }

  if (WiFi.status() != WL_CONNECTED) {
    if (millis() - lastWifiReconnectAt >= WIFI_RECONNECT_INTERVAL_MS) {
      lastWifiReconnectAt = millis();
      connectWifi();
    }
    return;
  }

  if (millis() - lastApiPollAt >= API_POLL_INTERVAL_MS) {
    lastApiPollAt = millis();
    getLastCommand();
  }
}

void setupMotors() {
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

#if ESP_ARDUINO_VERSION_MAJOR >= 3
  ledcAttach(ENA, PWM_FREQ, PWM_RES);
  ledcAttach(ENB, PWM_FREQ, PWM_RES);
#else
  ledcSetup(LEFT_PWM_CHANNEL, PWM_FREQ, PWM_RES);
  ledcSetup(RIGHT_PWM_CHANNEL, PWM_FREQ, PWM_RES);
  ledcAttachPin(ENA, LEFT_PWM_CHANNEL);
  ledcAttachPin(ENB, RIGHT_PWM_CHANNEL);
#endif

  stopCar();
}

void setupBluetooth() {
  if (!SerialBT.begin(DEVICE_NAME)) {
    Serial.println("Bluetooth failed to start");
    return;
  }

  Serial.print("Bluetooth name: ");
  Serial.println(DEVICE_NAME);
}

void setupWifiApi() {
  secureClient.setInsecure();

  if (!wifiApiConfigured()) {
    Serial.println("WiFi/API mode is disabled. Fill WiFi, login, and carId settings to enable it.");
    return;
  }

  connectWifi();
  if (WiFi.status() == WL_CONNECTED) {
    fetchToken();
  }
}

bool wifiApiConfigured() {
  return strlen(ssid) > 0 &&
         strcmp(ssid, "your_wifi_name") != 0 &&
         strlen(password) > 0 &&
         strcmp(password, "your_wifi_password") != 0 &&
         strlen(carEmail) > 0 &&
         strcmp(carEmail, "your_email@example.com") != 0 &&
         strlen(carPassword) > 0 &&
         strcmp(carPassword, "your_password") != 0 &&
         carId.length() > 0 &&
         carId != "your_car_id";
}

void connectWifi() {
  Serial.print("Connecting to WiFi");
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  for (int attempt = 0; attempt < 20 && WiFi.status() != WL_CONNECTED; attempt++) {
    delay(250);
    Serial.print(".");
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("WiFi connected. IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("WiFi connection failed");
  }
}

bool ensureToken() {
  if (jwtToken.length() > 0) {
    return true;
  }

  if (millis() - lastLoginAttemptAt < LOGIN_RETRY_INTERVAL_MS) {
    return false;
  }

  lastLoginAttemptAt = millis();
  return fetchToken();
}

bool fetchToken() {
  if (WiFi.status() != WL_CONNECTED) {
    return false;
  }

  HTTPClient http;
  String url = String(baseUrl) + loginEndpoint;

  Serial.println("Attempting API login...");
  http.begin(secureClient, url);
  http.addHeader("Content-Type", "application/json");

  DynamicJsonDocument reqDoc(256);
  reqDoc["email"] = carEmail;
  reqDoc["password"] = carPassword;

  String body;
  serializeJson(reqDoc, body);

  int code = http.POST(body);
  if (code == 200) {
    String response = http.getString();
    DynamicJsonDocument resDoc(1024);
    DeserializationError error = deserializeJson(resDoc, response);

    if (!error && resDoc["token"].is<const char *>()) {
      jwtToken = resDoc["token"].as<String>();
      Serial.println("API login successful");
      http.end();
      return true;
    }

    Serial.println("API login response did not include a token");
  } else {
    Serial.printf("API login failed. HTTP code: %d\n", code);
  }

  http.end();
  return false;
}

void getLastCommand() {
  if (!ensureToken()) {
    return;
  }

  HTTPClient http;
  String url = String(baseUrl) + "/api/commands/last/" + carId;

  http.begin(secureClient, url);
  http.addHeader("Authorization", "Bearer " + jwtToken);

  int code = http.GET();

  if (code == 200) {
    String response = http.getString();
    DynamicJsonDocument doc(2048);
    DeserializationError error = deserializeJson(doc, response);

    if (error) {
      Serial.print("Command JSON parse error: ");
      Serial.println(error.c_str());
      http.end();
      return;
    }

    if (doc["command"].isNull()) {
      stopCar();
      http.end();
      return;
    }

    JsonObject commandObject = doc["command"].as<JsonObject>();
    String command = commandObject["commandValue"] | "";
    int speed = commandObject["speed"] | DEFAULT_SPEED;

    if (command != lastApiCommand || speed != lastApiSpeed) {
      lastApiCommand = command;
      lastApiSpeed = speed;
      Serial.print("API command: ");
      Serial.print(command);
      Serial.print(" | Speed: ");
      Serial.println(speed);
    }

    timedStopAt = 0;
    pendingTimedDoneMessage = "";
    controlCar(command, speed);
  } else if (code == 401) {
    jwtToken = "";
    Serial.println("API token expired. Will log in again.");
  } else {
    Serial.printf("Command request failed. HTTP code: %d\n", code);
  }

  http.end();
}

void handleBluetooth() {
  while (SerialBT.available()) {
    char command = SerialBT.read();
    if (command == '\n' || command == '\r') {
      continue;
    }

    handleBluetoothCommand(command);
  }
}

void handleBluetoothCommand(char command) {
  Serial.print("Bluetooth command: ");
  Serial.println(command);

  switch (command) {
    case '1':
      runTimedCommand("B", DEFAULT_SPEED, 1000, "DONE: backward");
      break;
    case '2':
      runTimedCommand("L", DEFAULT_SPEED, 1000, "DONE: left");
      break;
    case '3':
      runTimedCommand("R", DEFAULT_SPEED, 1000, "DONE: right");
      break;
    case '4':
      runTimedCommand("F", DEFAULT_SPEED, 3000, "DONE: forward");
      break;
    case 'F':
    case 'f':
      timedStopAt = 0;
      pendingTimedDoneMessage = "";
      forward(DEFAULT_SPEED);
      SerialBT.println("DONE: forward");
      break;
    case 'B':
    case 'b':
      timedStopAt = 0;
      pendingTimedDoneMessage = "";
      backward(DEFAULT_SPEED);
      SerialBT.println("DONE: backward");
      break;
    case 'L':
    case 'l':
      timedStopAt = 0;
      pendingTimedDoneMessage = "";
      left(DEFAULT_SPEED);
      SerialBT.println("DONE: left");
      break;
    case 'R':
    case 'r':
      timedStopAt = 0;
      pendingTimedDoneMessage = "";
      right(DEFAULT_SPEED);
      SerialBT.println("DONE: right");
      break;
    case '0':
    case 'S':
    case 's':
      timedStopAt = 0;
      pendingTimedDoneMessage = "";
      stopCar();
      SerialBT.println("DONE: stop");
      break;
    default:
      SerialBT.println("ERROR: unknown command");
      break;
  }
}

void runTimedCommand(String command, int speed, unsigned long durationMs, const char *doneMessage) {
  controlCar(command, speed);
  timedStopAt = millis() + durationMs;
  pendingTimedDoneMessage = doneMessage;
}

void controlCar(String command, int speed) {
  command.trim();
  command.toUpperCase();
  speed = constrain(speed, 0, 255);

  if (command == "" || command == "NULL" || command == "S" || command == "0") {
    stopCar();
  } else if (command == "F" || command == "4") {
    forward(speed);
  } else if (command == "B" || command == "1") {
    backward(speed);
  } else if (command == "L" || command == "2") {
    left(speed);
  } else if (command == "R" || command == "3") {
    right(speed);
  } else {
    stopCar();
  }
}

void forward(int speed) {
  setMotorSpeed(speed, speed);
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
}

void backward(int speed) {
  setMotorSpeed(speed, speed);
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
}

void left(int speed) {
  setMotorSpeed(speed, speed);
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
}

void right(int speed) {
  setMotorSpeed(speed, speed);
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
}

void stopCar() {
  setMotorSpeed(0, 0);
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}

void setMotorSpeed(int leftSpeed, int rightSpeed) {
  leftSpeed = constrain(leftSpeed, 0, 255);
  rightSpeed = constrain(rightSpeed, 0, 255);
  writePwm(leftSpeed, rightSpeed);
}

void writePwm(int leftSpeed, int rightSpeed) {
#if ESP_ARDUINO_VERSION_MAJOR >= 3
  ledcWrite(ENA, leftSpeed);
  ledcWrite(ENB, rightSpeed);
#else
  ledcWrite(LEFT_PWM_CHANNEL, leftSpeed);
  ledcWrite(RIGHT_PWM_CHANNEL, rightSpeed);
#endif
}
