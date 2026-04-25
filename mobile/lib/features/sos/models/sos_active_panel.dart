import 'package:flutter/material.dart';

enum SOSActivePanel {
  sos,
  messages,
  guide;

  static SOSActivePanel fromQueryValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'messages':
        return SOSActivePanel.messages;
      case 'guide':
        return SOSActivePanel.guide;
      case 'sos':
      default:
        return SOSActivePanel.sos;
    }
  }

  String get queryValue => name;

  String get label {
    switch (this) {
      case SOSActivePanel.sos:
        return 'SOS';
      case SOSActivePanel.messages:
        return 'Messages';
      case SOSActivePanel.guide:
        return 'Guide';
    }
  }

  IconData get icon {
    switch (this) {
      case SOSActivePanel.sos:
        return Icons.radio_button_checked;
      case SOSActivePanel.messages:
        return Icons.chat_bubble_outline;
      case SOSActivePanel.guide:
        return Icons.info_outline;
    }
  }
}
