import 'dart:async';
import 'package:data_connection_checker_tv/data_connection_checker.dart';
import 'package:flutter/material.dart';

class NetworkBanner extends StatefulWidget {
  final Widget child;
  const NetworkBanner({super.key, required this.child});

  @override
  State<NetworkBanner> createState() => _NetworkBannerState();
}

class _NetworkBannerState extends State<NetworkBanner>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<DataConnectionStatus> _subscription;
  bool _isOffline = false;
  bool _showReconnected = false;
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

    _subscription = DataConnectionChecker().onStatusChange.listen((status) {
      final offline = status == DataConnectionStatus.disconnected;
      if (offline != _isOffline) {
        setState(() {
          _isOffline = offline;
          _showReconnected = !offline;
        });
        if (offline) {
          _ctrl.forward();
        } else {
          // Afficher "reconnecté" 2s puis masquer
          _ctrl.forward();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _ctrl.reverse().then((_) {
                if (mounted) setState(() => _showReconnected = false);
              });
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _isOffline || _showReconnected;
    return Column(
      children: [
        if (visible)
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(_slideAnim),
            child: _isOffline ? const _OfflineBanner() : const _OnlineBanner(),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFFDC2626),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Pas de connexion internet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineBanner extends StatelessWidget {
  const _OnlineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFF16A34A),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Connexion rétablie',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
