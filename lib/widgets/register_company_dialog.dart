import '../app_imports.dart';

class RegisterCompanyDialog {
  static void show(
    BuildContext context, {
    required Function(String phone, String password) onSuccess,
  }) {
    final TextEditingController companyEmailController = TextEditingController();
    final TextEditingController companyNameController = TextEditingController();
    final TextEditingController newFirstNameController = TextEditingController();
    final TextEditingController newUsernameController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController securityAnswerController = TextEditingController();

    String selectedSecurityQuestion = '�� �� ����� �����߿';
    String selectedUserRole = '���� ������';

    final List<String> securityQuestions = [
      '�� �� ����� �����߿',
      '�� �� ���� ������ �� ������ɿ',
      '�� �� ��� ������ ������ �����'
    ];

    final List<String> availableRoles = [
      '����',
      '���� ����',
      '���� ������',
      '�����',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: const Color(0xFF2C2C2C),
                title: const Text(
                  '����� ���� ����� ������ ��������',
                  style: TextStyle(color: Colors.amberAccent, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: companyEmailController,
                        style: const TextStyle(color: Colors.cyanAccent),
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: '������� ������� ����� ������',
                          labelStyle: TextStyle(color: Colors.cyanAccent),
                          prefixIcon: Icon(Icons.mark_email_read, color: Colors.cyanAccent),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: companyNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: '��� ������ �� ������ �������',
                          labelStyle: TextStyle(color: Colors.amberAccent),
                          prefixIcon: Icon(Icons.business, color: Colors.amberAccent),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: newFirstNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: '��� ������ �������',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.person, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: newUsernameController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: const InputDecoration(
                          labelText: '��� �������� (��� �������� - 11 ���)',
                          labelStyle: TextStyle(color: Colors.amber),
                          prefixIcon: Icon(Icons.phone_android, color: Colors.amber),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: newPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: '���� ����',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.lock, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedUserRole,
                        dropdownColor: const Color(0xFF1E1E1E),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: '�������� ������ �� ��������',
                          labelStyle: TextStyle(color: Colors.amberAccent),
                          prefixIcon: Icon(Icons.admin_panel_settings, color: Colors.amberAccent),
                        ),
                        items: availableRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedUserRole = val);
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: selectedSecurityQuestion,
                        dropdownColor: const Color(0xFF1E1E1E),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: '���� ������ ���������',
                          labelStyle: TextStyle(color: Colors.amberAccent),
                          prefixIcon: Icon(Icons.security, color: Colors.amberAccent),
                        ),
                        items: securityQuestions.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedSecurityQuestion = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: securityAnswerController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: '����� ���� ������',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.question_answer, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('�����', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                    onPressed: () async {
                      String rawEmail = companyEmailController.text.trim();
                      String comp = companyNameController.text.trim();
                      String fName = newFirstNameController.text.trim();
                      String phoneUser = newUsernameController.text.trim();
                      String pass = newPasswordController.text.trim();
                      String ans = securityAnswerController.text.trim();

                      if (comp.isEmpty || phoneUser.isEmpty || pass.isEmpty || fName.isEmpty || ans.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('������ ����� ���� �������� ����� ������!'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      if (!AuthService.isValidEgyptianPhone(phoneUser)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  '������ ����� ��� ������ ���� ���� �� 11 ��� ���� �� (010, 011, 012, 015, 040)!'),
                              backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      String companyAdminGmail = rawEmail.isNotEmpty ? rawEmail : 'captain.support640@gmail.com';

                      await AppStorageManager.registerEmployeeInTree(
                        companyAdminEmail: companyAdminGmail,
                        employeePhone: phoneUser,
                        employeeName: fName,
                        password: pass,
                        role: selectedUserRole,
                      );

                      String autoEmail = "$phoneUser@aqarat.com";

                      LoginScreen.mainCompanyName = comp;
                      LoginScreen.appUsers[phoneUser] = {
                        'company': comp,
                        'firstName': fName,
                        'password': pass,
                        'role': selectedUserRole,
                        'license': '���� ������� 30 ���',
                        'question': selectedSecurityQuestion,
                        'answer': ans,
                        'email': autoEmail,
                        'personalGmail': companyAdminGmail,
                      };

                      await LocalStorageService.saveAppUsers(LoginScreen.appUsers);
                      onSuccess(phoneUser, pass);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('�� ����� ������ �����!'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    child: const Text('��� ������', style: TextStyle(color: Colors.white)),
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