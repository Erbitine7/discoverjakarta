import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_notifier.dart';
import '../models/area.dart';
import '../services/api_service.dart';

class Home extends StatelessWidget {
  final bool isAdmin;
  final AuthNotifier auth;

  const Home({
    required this.auth,
    this.isAdmin = false,
    super.key,
  });

  Future<void> _logout(BuildContext context) async {
    final t = auth.token;
    if (t != null) {
      try {
        await apiService.logout(t);
      } catch (_) {}
    }
    await auth.setToken(null);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Discover Jakarta'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _logout(context),
            )
          else
            IconButton(
              icon: const Icon(Icons.login_outlined, size: 22, color: Colors.grey),
              tooltip: 'Admin login',
              onPressed: () => context.push('/admin/login'),
            ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 476,
          height: 476,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(jakartaAreas.length, (i) {
              final area = jakartaAreas[i];
              return _area(
                area.name,
                area.color,
                _offsets[i],
                '/pois/${area.id}',
                context,
              );
            }),
          ),
        ),
      ),
    );
  }
}

extension HexColor on String {
  Color toColor() {
    var hexString = this;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

final List<Offset> _offsets = [
  const Offset(0, 0),
  const Offset(0, -162),
  const Offset(0, 162),
  const Offset(-162, 0),
  const Offset(162, 0),
];

Widget _area(String text, String bgColor, Offset offset, String pushTo, BuildContext context) {
  return Transform.translate(
    offset: offset,
    child: ElevatedButton(
      onPressed: () => context.push(pushTo),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor.toColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        fixedSize: const Size(152, 152),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
