import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class SOSResolvedScreen extends StatelessWidget {
  final String incidentId;
  const SOSResolvedScreen({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // green checkmark
              Container(
                width: 80, height: 80,
                margin: const EdgeInsets.only(bottom: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kSecondary.withOpacity(0.15),
                  border: Border.all(color: kSecondary, width: 2),
                ),
                child: const Icon(Icons.check, color: kSecondary, size: 40),
              ),
              Text('Emergency Resolved',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Help has been notified.\nYou are safe.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextMuted, height: 1.5)),
              const SizedBox(height: 32),
              // incident ref card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.confirmation_number_outlined,
                    color: kTextMuted, size: 16),
                  const SizedBox(width: 8),
                  const Text('Incident ID',
                    style: TextStyle(color: kTextMuted, fontSize: 13)),
                  const Spacer(),
                  Text(incidentId.length > 16
                    ? '${incidentId.substring(0, 16)}...'
                    : incidentId,
                    style: const TextStyle(
                      color: kTextPrimary, fontSize: 12,
                      fontFamily: 'monospace')),
                ]),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSecondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => context.go('/home'),
                child: const Text('Return to Home',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
