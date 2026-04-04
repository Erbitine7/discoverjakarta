import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_notifier.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthNotifier();
  await auth.load();
  runApp(MyApp(auth: auth));
}

class MyApp extends StatefulWidget {
  const MyApp({required this.auth, super.key});

  final AuthNotifier auth;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(widget.auth);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Discover Jakarta',
      routerConfig: _router,
    );
  }
}
