import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleOptionalService {
  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;

  Future<void> startBleScan() {
    return FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 6),
      androidUsesFineLocation: true,
    );
  }

  Future<void> stopBleScan() {
    return FlutterBluePlus.stopScan();
  }
}
