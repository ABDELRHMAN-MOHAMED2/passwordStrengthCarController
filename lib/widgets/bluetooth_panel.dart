import 'package:flutter/material.dart';

import '../models/bluetooth_device_info.dart';
import '../services/car_controller.dart';
import 'futuristic_panel.dart';

class BluetoothPanel extends StatelessWidget {
  const BluetoothPanel({super.key, required this.controller});

  final CarController controller;

  @override
  Widget build(BuildContext context) {
    final bluetooth = controller.bluetooth;
    final theme = Theme.of(context);

    return FuturisticPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                bluetooth.isConnected
                    ? Icons.bluetooth_connected_rounded
                    : Icons.bluetooth_searching_rounded,
                color: bluetooth.isConnected
                    ? const Color(0xFF32E875)
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bluetooth.isConnected
                      ? 'Connected to ${bluetooth.connectedDeviceName}'
                      : 'Bluetooth Connection',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: bluetooth.isScanning
                      ? bluetooth.stopScan
                      : controller.scanDevices,
                  icon: Icon(
                    bluetooth.isScanning
                        ? Icons.stop_rounded
                        : Icons.radar_rounded,
                  ),
                  label: Text(bluetooth.isScanning ? 'Stop Scan' : 'Scan'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Auto reconnect',
                onPressed: bluetooth.autoReconnect,
                icon: const Icon(Icons.replay_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Disconnect',
                onPressed: bluetooth.isConnected ? bluetooth.disconnect : null,
                icon: const Icon(Icons.link_off_rounded),
              ),
            ],
          ),
          if (bluetooth.isScanning) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 3),
          ],
          if (bluetooth.lastError != null) ...[
            const SizedBox(height: 10),
            Text(
              bluetooth.lastError!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: bluetooth.devices.isEmpty
                ? Text(
                    'No ESP32 devices found yet',
                    key: const ValueKey('empty'),
                    style: TextStyle(color: Colors.white.withAlpha(150)),
                  )
                : Column(
                    key: const ValueKey('devices'),
                    children: bluetooth.devices
                        .map(
                          (device) => _DeviceTile(
                            device: device,
                            isConnected:
                                bluetooth.connectedDeviceAddress ==
                                    device.address &&
                                bluetooth.isConnected,
                            isConnecting: bluetooth.isConnecting,
                            onTap: () => bluetooth.connect(device),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.isConnected,
    required this.isConnecting,
    required this.onTap,
  });

  final BluetoothDeviceInfo device;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isConnected ? Icons.check_circle_rounded : Icons.memory_rounded,
        color: isConnected ? const Color(0xFF32E875) : Colors.white70,
      ),
      title: Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          device.address,
          if (device.isBonded) 'paired',
          if (device.rssi != null) '${device.rssi} dBm',
        ].join('  |  '),
      ),
      trailing: isConnecting
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right_rounded),
      onTap: isConnecting ? null : onTap,
    );
  }
}
