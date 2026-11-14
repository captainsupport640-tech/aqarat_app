import '../app_imports.dart';

class TrashBinManager {
  static void showTrashBinDialog(BuildContext context, {VoidCallback? onUpdate}) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            if (!AppData.storage.containsKey('trash_bin') || AppData.storage['trash_bin'] == null) {
              AppData.storage['trash_bin'] = [];
            }
            List trashList = AppData.storage['trash_bin']!;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.delete_sweep, color: Colors.amberAccent, size: 26),
                        SizedBox(width: 8),
                        Text(
                          '��� �������� (������ ���� 30 ���)',
                          style: TextStyle(color: Colors.amberAccent, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (trashList.isNotEmpty)
                      TextButton.icon(
                        onPressed: () async {
                          setDialogState(() {
                            AppData.storage['trash_bin'] = [];
                          });
                          if (onUpdate != null) onUpdate();
                          await LocalStorageService.saveLocally();
                          CloudSyncService.syncToCloud(isAuto: true);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('�� ����� ��� �������� ������� �����!'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.cleaning_services, color: Colors.redAccent, size: 18),
                        label: const Text(
                          '����� ����� �������',
                          style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                content: SizedBox(
                  width: 520,
                  height: 360,
                  child: trashList.isEmpty
                      ? const Center(
                          child: Text(
                            '��� �������� ����� ������.\n�� ���� ��� ���� �� �� ���� ����� ��� ���� 30 �����.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          itemCount: trashList.length,
                          itemBuilder: (context, index) {
                            final item = Map<String, dynamic>.from(trashList[index]);
                            String sourceScreen = item['source_screen'] ?? '��� �����';
                            String deletedDate = item['deleted_date'] ?? '-';

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2C),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade800),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '�����: $sourceScreen (����� �����: $deletedDate)',
                                          style: const TextStyle(
                                            color: Colors.amberAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.entries
                                              .where((e) => e.key != 'source_screen' && e.key != 'deleted_date')
                                              .map((e) => '${e.key}: ${e.value}')
                                              .take(4)
                                              .join(' | '),
                                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.restore_from_trash, color: Colors.greenAccent, size: 22),
                                    tooltip: '������� �����',
                                    onPressed: () async {
                                      String targetScreen = item['source_screen'] ?? '������ �������';
                                      Map<String, String> restoredItem = Map<String, String>.from(item);
                                      restoredItem.remove('source_screen');
                                      restoredItem.remove('deleted_date');

                                      setDialogState(() {
                                        if (!AppData.storage.containsKey(targetScreen) ||
                                            AppData.storage[targetScreen] == null) {
                                          AppData.storage[targetScreen] = [];
                                        }
                                        (AppData.storage[targetScreen] as List).add(restoredItem);
                                        trashList.removeAt(index);
                                      });

                                      if (onUpdate != null) onUpdate();
                                      await LocalStorageService.saveLocally();
                                      CloudSyncService.syncToCloud(isAuto: true);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('�� ������� ����� ����� ��� ��� ($targetScreen)'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 22),
                                    tooltip: '��� �����',
                                    onPressed: () async {
                                      setDialogState(() {
                                        trashList.removeAt(index);
                                      });
                                      if (onUpdate != null) onUpdate();
                                      await LocalStorageService.saveLocally();
                                      CloudSyncService.syncToCloud(isAuto: true);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('�� ��� ����� ���� �����!'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('�����', style: TextStyle(color: Colors.cyanAccent)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}