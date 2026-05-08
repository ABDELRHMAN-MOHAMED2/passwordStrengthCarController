# Password Strength Car Controller

A complete Flutter Android + ESP32 smart car project. The Android app analyzes a typed password in real time, maps the detected strength to command `1`, `2`, `3`, or `4`, and sends that command over Classic Bluetooth SPP to an ESP32 running `BluetoothSerial.h`.

## What Is Included

- Flutter Android app with Material Design 3 dark futuristic UI
- Real-time password strength analysis with entropy score
- Classic Bluetooth scanner, paired device list, connection status, auto reconnect, and command sending
- Last connected device storage with `shared_preferences`
- Password history and strength statistics
- Vibration and system click feedback when the strength level changes
- ESP32 Arduino firmware for an L298N two-motor car
- Wiring and setup notes
- Optional BLE scaffold in `lib/services/ble_optional_service.dart`

## Password Levels

| Level | Label | Command | Car movement |
| --- | --- | --- | --- |
| 1 | Very Weak | `1` | Backward for 1 second |
| 2 | Weak | `2` | Turn left for 1 second |
| 3 | Strong | `3` | Turn right for 1 second |
| 4 | Very Strong | `4` | Forward for 3 seconds |

After every movement the ESP32 stops both motors automatically.

## Flutter Packages

The app uses:

- `flutter_bluetooth_serial` for ESP32 Classic Bluetooth SPP
- `flutter_blue_plus` as an optional BLE scaffold
- `permission_handler`
- `shared_preferences`
- `provider`
- `vibration`

## Build The Android APK

```bash
flutter pub get
flutter build apk --release
```

The APK will be created at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

For quick testing with a connected Android phone:

```bash
flutter run
```

## Android Permissions

The app requests:

- `BLUETOOTH`, `BLUETOOTH_ADMIN` for Android 11 and lower
- `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE` for Android 12+
- `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` for Bluetooth discovery compatibility

Grant Bluetooth and location permissions when Android asks. On some phones, pair with the ESP32 in Android Bluetooth settings before connecting inside the app.

## ESP32 Firmware

Open this file in Arduino IDE:

```text
esp32_firmware/password_strength_car/password_strength_car.ino
```

Install/select:

- Arduino IDE
- ESP32 board support package
- Board: `ESP32 Dev Module`
- Library: built-in ESP32 `BluetoothSerial`

Upload the sketch. The Bluetooth device name is:

```text
ESP32_PASSWORD_CAR
```

## Wiring

Default ESP32 to L298N wiring:

| L298N pin | ESP32 pin |
| --- | --- |
| IN1 | GPIO 26 |
| IN2 | GPIO 27 |
| IN3 | GPIO 14 |
| IN4 | GPIO 12 |

Power wiring:

- Battery `+` to L298N motor power input
- Battery `-` to L298N GND
- ESP32 GND to L298N GND
- Left DC motor to L298N OUT1/OUT2
- Right DC motor to L298N OUT3/OUT4

Do not power motors directly from the ESP32. Use the battery pack through the L298N motor power input.

## How To Use

1. Upload the ESP32 firmware.
2. Turn on the car.
3. Pair the phone with `ESP32_PASSWORD_CAR` in Android Bluetooth settings if needed.
4. Run or install the Flutter app.
5. Tap scan, select the ESP32, type a password, then tap `Send to Car`.

## Project Structure

```text
lib/
  main.dart
  models/
  screens/
  services/
  utils/
  widgets/
esp32_firmware/
  password_strength_car/
    password_strength_car.ino
```

## Optional Advanced Ideas

- BLE support: replace the ESP32 firmware with a BLE GATT service and use `BleOptionalService`.
- Wi-Fi control: run an ESP32 WebServer endpoint such as `/command?value=4`.
- Firebase logging: upload anonymized command level, entropy score, and timestamp.
- Voice assistant: add Android speech-to-text commands for scan/connect/send.
- Obstacle avoidance: add an HC-SR04 ultrasonic sensor and ignore forward commands when blocked.
- OLED display: show the last command and connection state on an I2C SSD1306 screen.
- Live telemetry: send battery voltage and motor state back over Bluetooth.
