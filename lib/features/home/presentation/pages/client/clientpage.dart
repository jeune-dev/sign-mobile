import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../../account/presentation/pages/profil_page.dart';
import '../../../../particulier/presentation/bloc/particulier_bloc.dart';
import '../../../../particulier/presentation/pages/dashboard_client_page.dart';
import '../../../../particulier/presentation/pages/factures_client_page.dart';
import '../../../../particulier/presentation/pages/contrats_client_page.dart';

class ClientPage extends StatefulWidget {
  final User? user;

  const ClientPage({super.key, this.user});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  int _currentIndex = 0;

  void _logout() {
    context.read<AuthBloc>().add(LogoutRequested());
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
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
            const ProfilPage(), // ProfilPage charge l'utilisateur via AccountBloc
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
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _logout,
                  tooltip: 'Déconnexion',
                ),
              ],
            ),
            body: IndexedStack(
              index: _currentIndex,
              children: pages,
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
