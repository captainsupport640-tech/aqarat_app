import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'security_manager.dart';

class SupportService {
  static final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  static StreamSubscription? _sessionSubscription;

  /// 🚀 إرسال طلب دعم فني مباشر وتوليد كود جلسة مؤقت من 4 أرقام
  static Future<void> requestRemoteSupport(BuildContext context) async {
    String sessionCode = (1000 + Random().nextInt(9000)).toString();
    String companyEmail = SecurityManager.currentCompanyAdminEmail;
    String userPhone = SecurityManager.currentUserPhone;

    try {
      // رفع طلب الجلسة على السيرفر في قسم support_requests
      await _dbRef.child("support_requests").child(sessionCode).set({
        'session_code': sessionCode,
        'company_email': companyEmail.isEmpty ? 'captain.support640@gmail.com' : companyEmail,
        'requested_by_phone': userPhone.isEmpty ? 'عميل' : userPhone,
        'status': 'waiting', // waiting | connected | closed
        'created_at': DateTime.now().toIso8601String(),
      });

      if (context.mounted) {
        _showSupportClientDialog(context, sessionCode);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ تعذر إرسال طلب الدعم: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  /// 🔔 شاشة الانتظار للعميل بكود الجلسة حتى يفتح المبرمج الربط المباشر
  static void _showSupportClientDialog(BuildContext context, String sessionCode) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _dbRef.child("support_requests/$sessionCode/status").onValue.listen((event) {
      if (event.snapshot.exists) {
        String status = event.snapshot.value.toString();
        if (status == 'connected' && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚡ المبرمج متصل معك الآن وجاري تقديم الدعم الفني اللحظي...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.cyanAccent, width: 2),
          ),
          title: const Row(
            children: [
              Icon(Icons.headset_mic, color: Colors.cyanAccent, size: 28),
              SizedBox(width: 10),
              Text('الدعم الفني والتحكم عن بُعد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تم إرسال إشارة طلب الدعم للمبرمج بنجاح.\nيرجى تزويد المبرمج بكود الجلسة لتأكيد الاتصال المباشر:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber, width: 1.5),
                ),
                child: Text(
                  sessionCode,
                  style: const TextStyle(color: Colors.amber, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 4),
                ),
              ),
              const SizedBox(height: 15),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)),
                  SizedBox(width: 10),
                  Text('في انتظار قبول المبرمج للجلسة...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                _sessionSubscription?.cancel();
                await _dbRef.child("support_requests").child(sessionCode).remove();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('إلغاء الطلب', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}