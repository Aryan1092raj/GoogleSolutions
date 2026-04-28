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
      backgroundColor: kBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusStrip(),
                  const Spacer(),
                  _buildSuccessAnimation(),
                  const SizedBox(height: 26),
                  _buildTitle(context),
                  const SizedBox(height: 12),
                  _buildSubtitle(),
                  const SizedBox(height: 24),
                  _buildIncidentCard(),
                  const Spacer(),
                  _buildReturnButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0x1FFFFFFF),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, color: kSecondary, size: 16),
          SizedBox(width: 8),
          Text(
            'Incident status: Resolved',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: _checkScale,
      child: Container(
        width: 108,
        height: 108,
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0x1A22C55E),
          border: Border.all(
            color: kSecondary,
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: kSecondary,
          size: 54,
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
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w700,
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
            'Security acknowledged your SOS and closed this incident.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x1A22C55E),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0x6622C55E),
              ),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0x1FFFFFFF),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                color: kSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Incident Reference',
                    style: TextStyle(
                      color: kTextMuted,
                      fontSize: 11,
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
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kPanel,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0x1FFFFFFF),
                ),
              ),
              child: Text(
                widget.incidentId.length > 16
                    ? '${widget.incidentId.substring(0, 16)}...'
                    : widget.incidentId,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 12,
                  fontFamily: 'RobotoMono',
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
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPanel,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(
              color: Color(0x1FFFFFFF),
            ),
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
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
