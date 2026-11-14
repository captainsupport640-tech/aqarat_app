import '../app_imports.dart';

class CustomScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? extraActions;

  const CustomScreenAppBar({
    super.key,
    required this.title,
    this.extraActions,
  });

  @override
  Widget build(BuildContext context) {
    final filteredActions = extraActions?.where((w) => w is! LiveNotificationBell).toList();

    return AppBar(
      title: Text(
        title.isEmpty ? 'منظومة العقارات' : title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      automaticallyImplyLeading: false,
      actions: [
        if (filteredActions != null) ...filteredActions,
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00BCD4), Color(0xFF7C4DFF)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            tooltip: 'المساعد الذكي (AI Assistant)',
            onPressed: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (context) => const AiChatScreen()),
              );
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.home, color: Colors.amber, size: 24),
          tooltip: 'الشاشة الرئيسية',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 22),
          tooltip: 'إغلاق',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class LiveNotificationBell extends StatelessWidget {
  const LiveNotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}