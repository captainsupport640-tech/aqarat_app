import 'dart:io';
import 'package:flutter/material.dart';

class NetworkDevice {
  final String ipAddress;
  final String deviceName;
  bool isConnected;

  NetworkDevice({
    required this.ipAddress,
    required this.deviceName,
    this.isConnected = false,
  });
}

class LocalNetworkScannerService {
  /// دالة فحص الشبكة المحلية الحقيقية بالكامل (بدون أجهزة وهمية)
  static Future<List<NetworkDevice>> scanLocalNetwork() async {
    List<NetworkDevice> foundDevices = [];
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      if (interfaces.isNotEmpty) {
        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            String localIp = addr.address;
            List<String> parts = localIp.split('.');
            if (parts.length == 4) {
              String subnet = "${parts[0]}.${parts[1]}.${parts[2]}";

              // فحص متوازي للأجهزة الحقيقية من 1 إلى 50 على الشبكة
              List<Future<NetworkDevice?>> scanTasks = [];
              for (int i = 1; i <= 50; i++) {
                String targetIp = "$subnet.$i";
                if (targetIp == localIp) continue; // تجنب الجهاز الحالي

                scanTasks.add(_testDeviceConnection(targetIp));
              }

              // تجميع نتائج الفحص الحقيقي
              final results = await Future.wait(scanTasks);
              for (var dev in results) {
                if (dev != null) {
                  foundDevices.add(dev);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("خطأ في فحص الشبكة المحلية: $e");
    }

    return foundDevices;
  }

  /// اختبار اتصال Socket حقيقي بالجهاز على المنافذ الشائعة
  static Future<NetworkDevice?> _testDeviceConnection(String targetIp) async {
    List<int> portsToTest = [80, 8080, 443, 554];
    for (int port in portsToTest) {
      try {
        final socket = await Socket.connect(
          targetIp,
          port,
          timeout: const Duration(milliseconds: 120),
        );
        socket.destroy();
        return NetworkDevice(
          ipAddress: targetIp,
          deviceName: "جهاز شبكة نشط ($targetIp)",
          isConnected: false,
        );
      } catch (_) {}
    }
    return null;
  }
}

// واجهة عرض الأجهزة الحقيقية على الشبكة
class NetworkScannerScreen extends StatefulWidget {
  const NetworkScannerScreen({Key? key}) : super(key: key);

  @override
  _NetworkScannerScreenState createState() => _NetworkScannerScreenState();
}

class _NetworkScannerScreenState extends State<NetworkScannerScreen> {
  List<NetworkDevice> _devices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
    });

    List<NetworkDevice> results = await LocalNetworkScannerService.scanLocalNetwork();

    setState(() {
      _devices = results;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("الأجهزة المتصلة بالشبكة المحلية", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2D2D2D),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              onPressed: _isScanning ? null : _startScan,
              icon: _isScanning 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.refresh),
              label: Text(_isScanning ? "جاري فحص الأجهزة الحقيقية..." : "إعادة البحث عن أجهزة الشبكة"),
            ),
          ),
          Expanded(
            child: _isScanning && _devices.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : _devices.isEmpty
                    ? const Center(
                        child: Text(
                          "لم يتم العثور على أجهزة نشطة أخرى على نفس الشبكة حالياً",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          return Card(
                            color: const Color(0xFF2D2D2D),
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: Icon(
                                device.isConnected ? Icons.wifi_tethering : Icons.wifi,
                                color: device.isConnected ? Colors.greenAccent : Colors.amber,
                              ),
                              title: Text(device.deviceName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text("IP: ${device.ipAddress}", style: const TextStyle(color: Colors.grey)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: device.isConnected ? Colors.grey : Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        device.isConnected = !device.isConnected;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(device.isConnected 
                                              ? "تم ربط الجهاز ${device.ipAddress} بنجاح!" 
                                              : "تم فك ربط الجهاز ${device.ipAddress}"),
                                        ),
                                      );
                                    },
                                    child: Text(device.isConnected ? "مربوط" : "إضافة"),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                    onPressed: () {
                                      setState(() {
                                        _devices.removeAt(index);
                                      });
                                    },
                                    child: const Text("تجاهل"),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}