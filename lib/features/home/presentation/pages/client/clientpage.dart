import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:sign_application/core/widgets/logout_dialog.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import '../../../../account/presentation/pages/profil_page.dart';
import '../../../../particulier/presentation/bloc/particulier_bloc.dart';
import '../../../../particulier/presentation/pages/dashboard_client_page.dart';
import '../../../../particulier/presentation/pages/factures_client_page.dart';
import '../../../../particulier/presentation/pages/contrats_client_page.dart';
import 'package:sign_application/core/widgets/network_banner.dart';
import 'package:sign_application/core/services/fcm_service.dart';

class ClientPage extends StatefulWidget {
  final User? user;
  final int initialTabIndex;

  const ClientPage({super.key, this.user, this.initialTabIndex = 0});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmService.init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ParticulierBloc>(
      create: (_) => GetIt.instance<ParticulierBloc>(),
      child: Builder(
        builder: (ctx) {
          final List<Widget> pages = [
            DashboardClientPage(user: widget.user),
            const FacturesClientPage(),
            const ContratsClientPage(),
            const ProfilPage(),
          ];

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.user?.prenom ?? ''} ${widget.user?.nom ?? ''}'.trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if ((widget.user?.email ?? '').isNotEmpty)
                    Text(
                      widget.user!.email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  onPressed: () => LogoutDialog.show(ctx),
                  tooltip: 'Déconnexion',
                ),
              ],
            ),
            body: NetworkBanner(
              child: IndexedStack(
                index: _currentIndex,
                children: pages,
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'Factures',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.description_outlined),
                  activeIcon: Icon(Icons.description),
                  label: 'Contrats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
