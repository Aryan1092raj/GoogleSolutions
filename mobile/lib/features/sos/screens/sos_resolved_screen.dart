import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class SOSResolvedScreen extends StatefulWidget {
  final String incidentId;
  const SOSResolvedScreen({super.key, required this.incidentId});

  @override
  State<SOSResolvedScreen> createState() => _SOSResolvedScreenState();
}

class _SOSResolvedScreenState extends State<SOSResolvedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final AnimationController _fadeController;
  late final Animation<double> _checkScale;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    _checkController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBackground, Color(0xFF0A1929)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                _buildSuccessAnimation(),
                const SizedBox(height: 36),
                _buildTitle(context),
                const SizedBox(height: 12),
                _buildSubtitle(),
                const SizedBox(height: 40),
                _buildIncidentCard(),
                const Spacer(),
                _buildReturnButton(context),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: _checkScale,
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kSecondary.withOpacity(0.15),
          border: Border.all(
            color: kSecondary,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: kSecondary.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kSecondary,
                kSecondary.withOpacity(0.8),
              ],
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 60,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Text(
        'Emergency Resolved',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return FadeTransition(
      opacity: _fadeIn,
      child: Column(
        children: [
          const Text(
            'Help has been notified.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: kSecondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, color: kSecondary, size: 16),
                SizedBox(width: 6),
                Text(
                  'You are safe',
                  style: TextStyle(
                    color: kSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard() {
    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: kTextMuted.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                color: kPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incident Reference',
                  style: TextStyle(
                    color: kTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Keep this for your records',
                  style: TextStyle(
                    color: kTextMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.incidentId.length > 16
                    ? '${widget.incidentId.substring(0, 16)}...'
                    : widget.incidentId,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnButton(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kSecondary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kSecondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => context.go('/home'),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_outlined, size: 20),
              SizedBox(width: 10),
              Text(
                'Return to Home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
