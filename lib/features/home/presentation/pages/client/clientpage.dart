import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';

class ClientPage extends StatefulWidget {
  final User? user;

  const ClientPage({super.key, this.user});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // VULN-H02 : suppression du print (données sensibles)
  }

  // Méthode pour gérer la déconnexion
  void _logout() {
    context.read<AuthBloc>().add(LogoutRequested());
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = widget.user;

    // Créer les pages qui nécessitent les données utilisateur
    final List<Widget> _pages = [
      HomeClientPage(
        user: user,
        nombreFactures: 5,        // Ici tu peux mettre tes données dynamiques
        contratsSignes: 3,
        contratsEnAttente: 2,
      ),
      Center(child: Text('Factures', style: TextStyle(fontSize: 24))),
      Center(child: Text('Contrats', style: TextStyle(fontSize: 24))),
      ProfilPage(user: user),
      Center(child: Text('Déconnexion', style: TextStyle(fontSize: 24))),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (user?.prenom ?? '') + ' ' + (user?.nom ?? ''),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if ((user?.email ?? '').isNotEmpty)
              Text(
                user!.email,
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
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 4) { // dernier item => Déconnexion
            _logout();
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Factures',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Contrats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Déconnexion',
          ),
        ],
      ),
    );
  }
}

class HomeClientPage extends StatelessWidget {
  final User? user;

  // Tu peux passer ici les données réelles depuis ton backend
  final int nombreFactures;
  final int contratsSignes;
  final int contratsEnAttente;

  const HomeClientPage({
    super.key,
    this.user,
    this.nombreFactures = 0,
    this.contratsSignes = 0,
    this.contratsEnAttente = 0,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> cardsData = [
      {'title': 'Factures', 'value': nombreFactures.toString()},
      {'title': 'Contrats signés', 'value': contratsSignes.toString()},
      {'title': 'Contrats en attente', 'value': contratsEnAttente.toString()},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bienvenue
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),

          // Cartes de statistiques
          Expanded(
            child: GridView.builder(
              itemCount: cardsData.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                final card = cardsData[index];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card['value']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card['title']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilPage extends StatelessWidget {
  final User? user;

  const ProfilPage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations personnelles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (user != null) ...[
                    _buildInfoRow('Nom complet', '${user!.prenom} ${user!.nom}'),
                    _buildInfoRow('Email', user!.email),
                    _buildInfoRow('Téléphone', user!.telephone),
                    _buildInfoRow('Adresse', user!.adresse),
                    _buildInfoRow('Rôle', user!.role),
                    if (user!.carte_identite_national_num.isNotEmpty)
                      _buildInfoRow('CIN', user!.carte_identite_national_num),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}