import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/bluetooth_device_info.dart';
import 'local_storage_service.dart';

class BluetoothCarService extends ChangeNotifier {
  BluetoothCarService(this._storage);

  final LocalStorageService _storage;
  BluetoothConnection? _connection;
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;
  StreamSubscription<Uint8List>? _inputSubscription;

  final List<BluetoothDeviceInfo> _devices = [];
  List<BluetoothDeviceInfo> get devices => List.unmodifiable(_devices);

  bool isScanning = false;
  bool isConnecting = false;
  bool isConnected = false;
  String? connectedDeviceName;
  String? connectedDeviceAddress;
  String? lastError;
  String incomingLog = '';

  Future<void> initialize() async {
    await requestPermissions();
    await refreshBondedDevices();
    await autoReconnect();
  }

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );
  }

  Future<bool> _ensureBluetoothEnabled() async {
    final enabled = await FlutterBluetoothSerial.instance.isEnabled;
    if (enabled == true) return true;

    final requested = await FlutterBluetoothSerial.instance.requestEnable();
    if (requested == true) return true;

    lastError = 'Bluetooth is disabled';
    notifyListeners();
    return false;
  }

  Future<void> refreshBondedDevices() async {
    try {
      if (!await _ensureBluetoothEnabled()) return;

      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      for (final device in bonded) {
        _upsertDevice(
          BluetoothDeviceInfo(
            address: device.address,
            name: device.name ?? 'Unknown device',
            isBonded: true,
          ),
        );
      }
      notifyListeners();
    } catch (error) {
      lastError = 'Could not read paired Bluetooth devices: $error';
      notifyListeners();
    }
  }

  Future<void> startScan() async {
    if (isScanning) return;
    lastError = null;

    final allowed = await requestPermissions();
    if (!allowed) {
      lastError = 'Bluetooth permissions were not granted';
      notifyListeners();
      return;
    }

    if (!await _ensureBluetoothEnabled()) return;

    await refreshBondedDevices();
    isScanning = true;
    notifyListeners();

    _discoverySubscription = FlutterBluetoothSerial.instance
        .startDiscovery()
        .listen(
          (result) {
            _upsertDevice(
              BluetoothDeviceInfo(
                address: result.device.address,
                name: result.device.name ?? 'Unknown device',
                isBonded: result.device.isBonded,
                rssi: result.rssi,
              ),
            );
            notifyListeners();
          },
          onError: (Object error) {
            lastError = 'Bluetooth scan failed: $error';
            isScanning = false;
            notifyListeners();
          },
          onDone: () {
            isScanning = false;
            notifyListeners();
          },
        );
  }

  Future<void> stopScan() async {
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;
    isScanning = false;
    notifyListeners();
  }

  Future<void> connect(BluetoothDeviceInfo device) async {
    await stopScan();
    await disconnect();

    isConnecting = true;
    lastError = null;
    notifyListeners();

    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      isConnected = true;
      connectedDeviceAddress = device.address;
      connectedDeviceName = device.name;
      await _storage.saveLastDevice(address: device.address, name: device.name);

      _inputSubscription = _connection?.input?.listen(
        (data) {
          incomingLog = utf8.decode(data, allowMalformed: true).trim();
          notifyListeners();
        },
        onDone: () {
          _markDisconnected();
        },
        onError: (_) {
          _markDisconnected();
        },
      );
    } catch (error) {
      lastError = 'Could not connect to ${device.name}: $error';
      _markDisconnected();
    } finally {
      isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> autoReconnect() async {
    final saved = await _storage.loadLastDevice();
    if (saved == null || isConnected) return;

    await connect(
      BluetoothDeviceInfo(address: saved.address, name: saved.name),
    );
  }

  Future<void> sendCommand(String command) async {
    if (!isConnected || _connection == null) {
      throw StateError('Connect to the ESP32 car first');
    }

    _connection!.output.add(Uint8List.fromList(utf8.encode(command)));
    await _connection!.output.allSent;
  }

  Future<void> disconnect() async {
    await _inputSubscription?.cancel();
    _inputSubscription = null;
    await _connection?.close();
    _markDisconnected(clearDevice: false);
  }

  void _markDisconnected({bool clearDevice = true}) {
    isConnected = false;
    if (clearDevice) {
      connectedDeviceName = null;
      connectedDeviceAddress = null;
    }
    _connection = null;
    notifyListeners();
  }

  void _upsertDevice(BluetoothDeviceInfo device) {
    final index = _devices.indexWhere((item) => item.address == device.address);
    if (index == -1) {
      _devices.add(device);
      _devices.sort((a, b) {
        if (a.isBonded != b.isBonded) return a.isBonded ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    } else {
      _devices[index] = device.copyWith(isBonded: device.isBonded);
    }
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _inputSubscription?.cancel();
    _connection?.dispose();
    super.dispose();
  }
}
