# Password Strength Car Controller

A complete Flutter Android + ESP32 smart car project. The Android app analyzes a typed password in real time, maps the detected strength to command `1`, `2`, `3`, or `4`, and sends that command over Classic Bluetooth SPP to an ESP32. The ESP32 firmware also supports optional Wi-Fi/API polling with `F`, `B`, `L`, `R`, and `S` commands.

## What Is Included

- Flutter Android app with Material Design 3 dark futuristic UI
- Real-time password strength analysis with entropy score
- Classic Bluetooth scanner, paired device list, connection status, auto reconnect, and command sending
- Last connected device storage with `shared_preferences`
- Password history and strength statistics
- Vibration and system click feedback when the strength level changes
- ESP32 Arduino firmware for a four-motor car using one L298N wired as left-side and right-side motor channels
- Wiring and setup notes
- Optional BLE scaffold in `lib/services/ble_optional_service.dart`

## Password Levels

| Level | Label | Command | Car movement |
| --- | --- | --- | --- |
| 1 | Very Weak | `1` | Backward for 1 second |
| 2 | Weak | `2` | Turn left for 1 second |
| 3 | Strong | `3` | Turn right for 1 second |
| 4 | Very Strong | `4` | Forward for 3 seconds |

After every Bluetooth password movement the ESP32 stops all four motors automatically.

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
- Library: `ArduinoJson` for optional Wi-Fi/API mode

Upload the sketch. The Bluetooth device name is:

```text
ESP32_PASSWORD_CAR
```

The firmware has two control paths:

- Bluetooth app mode: keep the Wi-Fi placeholders unchanged, pair the phone with `ESP32_PASSWORD_CAR`, and use the Flutter app as before.
- Wi-Fi/API mode: fill in `ssid`, `password`, `carEmail`, `carPassword`, and `carId` in the sketch. The ESP32 logs in to `https://robodrive.runasp.net`, polls `/api/commands/last/{carId}`, and accepts `F`, `B`, `L`, `R`, `S` plus an optional `speed` value from `0` to `255`.

## Wiring

Default ESP32 to L298N wiring, matching the photo:

| L298N pin | ESP32 pin | Purpose |
| --- | --- | --- |
| IN1 | GPIO 27 | Left side direction |
| IN2 | GPIO 26 | Left side direction |
| ENA | GPIO 14 | Left side speed/PWM |
| IN3 | GPIO 25 | Right side direction |
| IN4 | GPIO 33 | Right side direction |
| ENB | GPIO 12 | Right side speed/PWM |

Four-motor output wiring:

| L298N output | Motors |
| --- | --- |
| OUT1/OUT2 | Front-left and rear-left motors |
| OUT3/OUT4 | Front-right and rear-right motors |

Connect the two left motors in parallel on `OUT1/OUT2`, and connect the two right motors in parallel on `OUT3/OUT4`. Keep the polarity the same for both motors on each side. If one side spins backward during a forward command, swap that side's motor wires.

Power wiring:

- Battery `+` to L298N motor power input
- Battery `-` to L298N GND
- ESP32 GND to L298N GND
- Remove the ENA/ENB jumpers if your L298N has them, because GPIO 14 and GPIO 12 provide PWM speed control

Do not power motors directly from the ESP32. Use the battery pack through the L298N motor power input. If the L298N overheats or the motors are weak, use a stronger motor driver or two L298N boards and duplicate the same left/right input signals to the extra board.

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
