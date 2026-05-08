class BluetoothDeviceInfo {
  const BluetoothDeviceInfo({
    required this.address,
    required this.name,
    this.isBonded = false,
    this.rssi,
  });

  final String address;
  final String name;
  final bool isBonded;
  final int? rssi;

  BluetoothDeviceInfo copyWith({
    String? address,
    String? name,
    bool? isBonded,
    int? rssi,
  }) {
    return BluetoothDeviceInfo(
      address: address ?? this.address,
      name: name ?? this.name,
      isBonded: isBonded ?? this.isBonded,
      rssi: rssi ?? this.rssi,
    );
  }
}
