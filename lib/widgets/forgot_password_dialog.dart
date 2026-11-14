import '../app_imports.dart';

class ForgotPasswordDialog {
  static void show(BuildContext context) {
    final TextEditingController recoverUserCtrl = TextEditingController();
    final TextEditingController recoverAnswerCtrl = TextEditingController();
    final TextEditingController newPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: const Color(0xFF2C2C2C),
                title: const Text('������� ������ ���� ����', style: TextStyle(color: Colors.amberAccent)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: recoverUserCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: const InputDecoration(
                        labelText: '��� �������� (��� �������� - 11 ���)',
                        labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.phone_android, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: recoverAnswerCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: '����� ���� ������', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPassCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: '���� ���� �������', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('�����', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
                    onPressed: () async {
                      String u = recoverUserCtrl.text.trim();
                      String a = recoverAnswerCtrl.text.trim();
                      String np = newPassCtrl.text.trim();

                      if (LoginScreen.appUsers.containsKey(u) && LoginScreen.appUsers[u]!['answer'] == a) {
                        LoginScreen.appUsers[u]!['password'] = np;
                        await LocalStorageService.saveAppUsers(LoginScreen.appUsers);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('�� ����� ���� ���� �����!'), backgroundColor: Colors.green),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('��� �������� �� ����� ���� ������ ��� �����!'),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: const Text('����� ���� ����',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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