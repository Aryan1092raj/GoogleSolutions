import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../providers/auth_provider.dart';

class GuestCheckinScreen extends ConsumerStatefulWidget {
  const GuestCheckinScreen({super.key});

  @override
  ConsumerState createState() {
    return _GuestCheckinScreenState();
  }
}

class _GuestCheckinScreenState extends ConsumerState {
  final _hotelIdController = TextEditingController();
  final _roomController = TextEditingController();
  final _nameController = TextEditingController();
  String _language = 'en';
  bool _loading = false;

  @override
  void dispose() {
    _hotelIdController.dispose();
    _roomController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continueToHome() async {
    final hotelId = _hotelIdController.text.trim();
    final room = _roomController.text.trim();
    final name = _nameController.text.trim();

    if (hotelId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hotel ID is required')));
      return;
    }
    if (room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room number is required')));
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guest name is required')));
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final uri = Uri.parse('${AppConstants.backendBaseUrl}/api/auth/guest-token');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hotelId': hotelId,
          'roomNumber': room,
          'guestName': name,
          'language': _language,
        }),
      );

      if (resp.statusCode != 200) {
        var message = 'Check-in failed';
        try {
          final parsed = jsonDecode(resp.body) as Map<String, dynamic>;
          if (parsed['error'] != null) {
            message = parsed['error'].toString();
          }
        } catch (_) {}
        throw Exception(message);
      }

      final parsed = jsonDecode(resp.body) as Map<String, dynamic>;
      final customToken = parsed['customToken']?.toString() ?? '';
      final guestId = parsed['guestId']?.toString() ?? '';

      if (customToken.isEmpty || guestId.isEmpty) {
        throw Exception('Invalid guest token response');
      }

      await FirebaseAuth.instance.signInWithCustomToken(customToken);

      ref.read(guestProfileProvider.notifier).setProfile(
            GuestProfile(
              guestId: guestId,
              guestName: name,
              roomNumber: room,
              language: _language,
              hotelId: hotelId,
            ),
          );

      if (mounted) {
        context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guest Check-In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _hotelIdController, decoration: const InputDecoration(labelText: 'Hotel ID')),
            const SizedBox(height: 12),
            TextField(controller: _roomController, decoration: const InputDecoration(labelText: 'Room Number')),
            const SizedBox(height: 12),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Guest Name')),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              initialValue: _language,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'hi', child: Text('Hindi')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _language = value.toString();
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _continueToHome,
              child: Text(_loading ? 'Checking in...' : 'Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
