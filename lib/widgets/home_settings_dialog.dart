import '../app_imports.dart';

class HomeSettingsDialog {
  static void show({
    required BuildContext context,
    required String initialBackupFrequency,
    required String initialPersonalGmail,
    required ValueChanged<String> onBackupFrequencyChanged,
    required ValueChanged<String> onPersonalGmailChanged,
    required VoidCallback onDataRestored,
  }) {
    if (SecurityManager.isGuest) {
      SecurityManager.showPermissionDeniedSnackBar(
          context, 'تنبيه هام: وضع التصفح لا يسمح بالدخول إلى إعدادات السيستم.');
      return;
    }

    String currentFreq = initialBackupFrequency;
    final TextEditingController activationController = TextEditingController();
    final TextEditingController googleDriveEmailController = TextEditingController(text: initialPersonalGmail);

    String myDeviceId = "CAPTAIN-PC-2026";
    String hardwareId = LicensingService.getDeviceHardwareId(myDeviceId);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          String currentPhone = SecurityManager.currentUsername;
          String generatedCompanyServerEmail = '$currentPhone@aqarat.com';

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings, color: Colors.amber, size: 28),
                  SizedBox(width: 8),
                  Text('إعدادات السيستم والنسخ',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: googleDriveEmailController,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'حساب Google Drive الشخصي (للنسخ الاحتياطي)',
                          labelStyle: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                          prefixIcon: const Icon(Icons.cloud_sync, color: Colors.amberAccent, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF141414),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) async {
                          final trimmed = val.trim();
                          onPersonalGmailChanged(trimmed);
                          await LocalStorageService.savePersonalGmail(trimmed);
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.admin_panel_settings, color: Colors.cyanAccent, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'حساب السيرفر الموحد: $generatedCompanyServerEmail',
                                style: const TextStyle(
                                    color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('جدولة النسخ الاحتياطي التلقائي:',
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: ['يومياً', 'أسبوعياً', 'شهرياً', 'يدوياً'].contains(currentFreq)
                            ? currentFreq
                            : 'يومياً',
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF141414),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: ['يومياً', 'أسبوعياً', 'شهرياً', 'يدوياً'].map((freq) {
                          return DropdownMenuItem(value: freq, child: Text(freq));
                        }).toList(),
                        onChanged: (val) async {
                          if (val != null) {
                            setDialogState(() => currentFreq = val);
                            onBackupFrequencyChanged(val);
                            await LocalStorageService.setBackupFrequency(val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          minimumSize: const Size(double.infinity, 42),
                          alignment: Alignment.centerRight,
                        ),
                        icon: const Icon(Icons.delete_sweep, color: Colors.white),
                        label: const Text('🗑️ سلة المهملات (استرجاع المحذوفات)',
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                        onPressed: () {
                          Navigator.pop(context);
                          TrashBinManager.showTrashBinDialog(context);
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          minimumSize: const Size(double.infinity, 42),
                          alignment: Alignment.centerRight,
                        ),
                        icon: const Icon(Icons.cloud_upload, color: Colors.white),
                        label: const Text('المزامنة السحابية الفورية (Firebase)',
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                        onPressed: () async {
                          await CloudSyncService.performCloudSync(context);
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          minimumSize: const Size(double.infinity, 42),
                          alignment: Alignment.centerRight,
                        ),
                        icon: const Icon(Icons.backup, color: Colors.white),
                        label: const Text('نسخ احتياطي محلي + تصدير ملف',
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                        onPressed: () async {
                          await FileBackupService.backupToFile(context);
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          minimumSize: const Size(double.infinity, 42),
                          alignment: Alignment.centerRight,
                        ),
                        icon: const Icon(Icons.restore, color: Colors.white),
                        label: const Text('استرجاع البيانات من ملف',
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                        onPressed: () async {
                          await FileBackupService.restoreFromFile(context);
                          await CloudSyncService.saveAndSyncInstant();
                          onDataRestored();
                        },
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade900,
                          minimumSize: const Size(double.infinity, 42),
                          alignment: Alignment.centerRight,
                        ),
                        icon: const Icon(Icons.admin_panel_settings, color: Colors.greenAccent),
                        label: const Text('🛠️ غرفة دعم المبرمج (التحكم عن بعد)',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          HomeRemoteSupportDialog.show(context);
                        },
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF282828),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('حالة ترخيص السيستم:',
                                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(
                              LicensingService.isMasterAdmin || LicensingService.isActivated
                                  ? 'الحالة: مفعل بالكامل'
                                  : LicensingService.activationType,
                              style: TextStyle(
                                  color: LicensingService.isMasterAdmin || LicensingService.isActivated
                                      ? Colors.greenAccent
                                      : Colors.cyanAccent,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('كود الجهاز: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Expanded(
                                  child: Text(
                                    hardwareId,
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.amber, size: 18),
                                  tooltip: 'نسخ كود الجهاز',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: hardwareId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('تم نسخ كود الجهاز بنجاح!'),
                                          backgroundColor: Colors.blue,
                                          duration: Duration(seconds: 2)),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: activationController,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                labelText: 'أدخل كود التفعيل من المبرمج',
                                labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                                filled: true,
                                fillColor: const Color(0xFF141414),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
                                onPressed: () async {
                                  bool success = await LicensingService.processActivationCode(
                                    inputCode: activationController.text,
                                    deviceId: myDeviceId,
                                  );
                                  if (success) {
                                    setDialogState(() {});
                                    onDataRestored();
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('تم تفعيل النسخة الكاملة بنجاح!'),
                                            backgroundColor: Colors.green),
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('كود التفعيل غير صحيح أو غير مطابق للجهاز!'),
                                            backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                                child: const Text('تفعيل النسخة الكاملة',
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}