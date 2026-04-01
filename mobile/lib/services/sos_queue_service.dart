import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for offline-first SOS queue management.
/// Stores pending SOS payloads in SharedPreferences when network is unavailable.
class SOSQueueService {
  static const String _pendingKey = 'pending_sos_payload';

  /// Save pending SOS payload to SharedPreferences.
  /// Returns true if successfully enqueued.
  static Future<bool> enqueue(Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(payload);
      return await prefs.setString(_pendingKey, encoded);
    } catch (_) {
      return false;
    }
  }

  /// Get pending SOS payload if any exists.
  /// Returns null if no pending SOS.
  static Future<Map<String, dynamic>?> peek() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_pendingKey);
      if (encoded == null) return null;
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  /// Remove pending SOS payload after successful submission.
  /// Returns true if successfully dequeued.
  static Future<bool> dequeue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_pendingKey);
    } catch (_) {
      return false;
    }
  }

  /// Check if a pending SOS exists in the queue.
  static Future<bool> hasPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_pendingKey);
    } catch (_) {
      return false;
    }
  }

  /// Clear all pending SOS data (used for cleanup).
  static Future<bool> clear() async {
    return dequeue();
  }
}
