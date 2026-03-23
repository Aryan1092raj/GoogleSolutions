import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../command/providers/incident_provider.dart';

class StaffLoginScreen extends ConsumerStatefulWidget {
  const StaffLoginScreen({super.key});
  @override
  ConsumerState createState() { return _StaffLoginScreenState(); }
}

class _StaffLoginScreenState extends ConsumerState {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _emailController.dispose(); _passwordController.dispose(); super.dispose(); }

  Future _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email is required'))); return; }
    if (password.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password is required'))); return; }
    setState(() { _loading = true; });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      final token = user == null ? null : await user.getIdTokenResult(true);
      final claims = token == null ? null : token.claims;
      final hotelId = claims == null ? '' : (claims['hotelId'] == null ? '' : claims['hotelId'].toString());
      final role = claims == null ? '' : (claims['role'] == null ? '' : claims['role'].toString());
      if (hotelId.isEmpty) {
        throw Exception('Missing hotelId claim on user token. Set custom claims first.');
      }
      ref.read(staffProfileProvider.notifier).state = StaffProfile(uid: user == null ? '' : user.uid, hotelId: hotelId, role: role);
      await markStaffOnline(ref.read(staffProfileProvider), name: email);
      if (context.mounted) { context.go('/dashboard'); }
    } catch (error) {
      if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: ' + error.toString()))); }
    }
    if (mounted) { setState(() { _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Login')),
      body: Center(
        child: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _loading ? null : _login, child: Text(_loading ? 'Signing in...' : 'Sign In')),
        ])),
      ),
    );
  }
}
