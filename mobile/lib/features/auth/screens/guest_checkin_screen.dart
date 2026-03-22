import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void dispose() {
    _hotelIdController.dispose();
    _roomController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _continueToHome() {
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
    ref.read(guestProfileProvider.notifier).setProfile(GuestProfile(guestName: name, roomNumber: room, language: _language, hotelId: hotelId));
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guest Check-In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(children: [
          TextField(controller: _hotelIdController, decoration: const InputDecoration(labelText: 'Hotel ID')),
          const SizedBox(height: 12),
          TextField(controller: _roomController, decoration: const InputDecoration(labelText: 'Room Number')),
          const SizedBox(height: 12),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Guest Name')),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: _language,
            items: const [DropdownMenuItem(value: 'en', child: Text('English')), DropdownMenuItem(value: 'hi', child: Text('Hindi'))],
            onChanged: (value) { if (value == null) { return; } setState(() { _language = value.toString(); }); },
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _continueToHome, child: const Text('Continue')),
        ]),
      ),
    );
  }
}
