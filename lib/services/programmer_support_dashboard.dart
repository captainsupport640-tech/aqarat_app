import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'security_manager.dart';

class ProgrammerSupportDashboard extends StatefulWidget {
  const ProgrammerSupportDashboard({super.key});

  @override
  State<ProgrammerSupportDashboard> createState() => _ProgrammerSupportDashboardState();
}

class _ProgrammerSupportDashboardState extends State<ProgrammerSupportDashboard> {
  final DatabaseReference _requestsRef = FirebaseDatabase.instance.ref("support_requests");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: const Text(
          '👑 لوحة المبرمج - التحكم والطلبات الحية',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF222222),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط معلومات المبرمج والامتيازات المطلقة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.amber.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'مرحباً بك يا كابتن! تم تفعيل وضع المبرمج بامتيازات مطلقة (${SecurityManager.currentUserEmail})',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FirebaseAnimatedList(
              query: _requestsRef,
              defaultChild: const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
              itemBuilder: (context, snapshot, animation, index) {
                if (!snapshot.exists || snapshot.value == null) {
                  return const SizedBox.shrink();
                }

                Map sessionData = Map.from(snapshot.value as Map);
                String sessionCode = sessionData['session_code'] ?? '';
                String companyEmail = sessionData['company_email'] ?? '';
                String phone = sessionData['requested_by_phone'] ?? '';
                String status = sessionData['status'] ?? 'waiting';

                return SizeTransition(
                  sizeFactor: animation,
                  child: Card(
                    color: const Color(0xFF242424),
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: status == 'connected' ? Colors.green : Colors.cyanAccent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: status == 'connected'
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.cyanAccent.withValues(alpha: 0.2),
                        child: Icon(
                          status == 'connected' ? Icons.phonelink_ring : Icons.headset_mic,
                          color: status == 'connected' ? Colors.green : Colors.cyanAccent,
                        ),
                      ),
                      title: Text(
                        'طلب من: $companyEmail',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        'الهاتف: $phone | كود الجلسة: $sessionCode',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: status == 'connected' ? Colors.orange : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            icon: Icon(
                              status == 'connected' ? Icons.visibility : Icons.play_arrow,
                              size: 16,
                            ),
                            label: Text(status == 'connected' ? 'عرض الشاشة' : 'بدء التحكم'),
                            onPressed: () async {
                              await _requestsRef.child(sessionCode).update({'status': 'connected'});
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('⚡ تم الربط المباشر بجلسة العميل $sessionCode'),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                            onPressed: () async {
                              await _requestsRef.child(sessionCode).remove();
                            },
                          ),
                        ],
                      ),
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