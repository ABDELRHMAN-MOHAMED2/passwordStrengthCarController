#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

// L298N motor driver pins. Change these values if your wiring is different.
const int IN1 = 26;  // Left motor input 1
const int IN2 = 27;  // Left motor input 2
const int IN3 = 14;  // Right motor input 1
const int IN4 = 12;  // Right motor input 2

const char *DEVICE_NAME = "ESP32_PASSWORD_CAR";

void setup() {
  Serial.begin(115200);

  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  stopMotors();

  if (!SerialBT.begin(DEVICE_NAME)) {
    Serial.println("Bluetooth failed to start");
    while (true) {
      delay(1000);
    }
  }

  Serial.println("ESP32 Password Strength Car is ready");
  Serial.print("Bluetooth name: ");
  Serial.println(DEVICE_NAME);
}

void loop() {
  if (!SerialBT.available()) {
    return;
  }

  char command = SerialBT.read();
  Serial.print("Received command: ");
  Serial.println(command);

  if (command == '1') {
    moveBackward();
    delay(1000);
    stopMotors();
    SerialBT.println("DONE: backward");
  } else if (command == '2') {
    turnLeft();
    delay(1000);
    stopMotors();
    SerialBT.println("DONE: left");
  } else if (command == '3') {
    turnRight();
    delay(1000);
    stopMotors();
    SerialBT.println("DONE: right");
  } else if (command == '4') {
    moveForward();
    delay(3000);
    stopMotors();
    SerialBT.println("DONE: forward");
  } else if (command == '0' || command == 'S' || command == 's') {
    stopMotors();
    SerialBT.println("DONE: stop");
  } else {
    SerialBT.println("ERROR: unknown command");
  }
}

void moveForward() {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
}

void moveBackward() {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
}

void turnLeft() {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, HIGH);
  digitalWrite(IN4, LOW);
}

void turnRight() {
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
}

void stopMotors() {
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}
