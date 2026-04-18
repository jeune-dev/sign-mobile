import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import './historique_factures_page.dart';
import './dio_handler.dart';

class HomeProfessionnelPage extends StatefulWidget {
  final User? user;
  const HomeProfessionnelPage({super.key, this.user});

  @override
  State<HomeProfessionnelPage> createState() => _HomeProfessionnelPageState();
}

class _HomeProfessionnelPageState extends State<HomeProfessionnelPage> {
  final Dio _dio = GetIt.instance<Dio>();
  List<dynamic> _recentDocuments = [];
  bool _isLoadingRecent = false;
  String _recentError = '';

  @override
  void initState() {
    super.initState();
    _fetchRecentDocuments();
  }

  Future<void> _fetchRecentDocuments() async {
    setState(() {
      _isLoadingRecent = true;
      _recentError = '';
    });
    try {
      await handleDioRequest(context, () async {
        final response = await _dio.get(
          '/professionnel/document/mes-documents',
          queryParameters: {'page': 1, 'limit': 4},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
        if (response.statusCode == 200) {
          setState(() {
            _recentDocuments = List<dynamic>.from(response.data['data'] ?? []);
            _isLoadingRecent = false;
          });
        } else {
          throw Exception('Erreur serveur: ${response.statusCode}');
        }
      });
    } catch (e) {
      setState(() {
        _recentError = 'Erreur: $e';
        _isLoadingRecent = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _telechargerDocument(String documentId) async {
    try {
      final Uri url = Uri.parse(
          'https://sign-backend-v1.onrender.com/sign/professionnel/document/telecharger-document/$documentId');
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Impossible');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aperçu de votre activité',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Grille des cartes (2 cartes seulement)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                final cardsData = [
                  {
                    'title': 'Clients actifs',
                    'value': '12',
                    'color': Colors.black87,
                    'icon': Icons.people,
                    'onTap': () {}
                  },
                  {
                    'title': 'Contrats en cours',
                    'value': '8',
                    'color': Colors.black87,
                    'icon': Icons.description,
                    'onTap': () {}
                  },
                ];
                final card = cardsData[index];
                return GestureDetector(
                  onTap: card['onTap'] as VoidCallback?,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      decoration: BoxDecoration(
                          color: card['color'] as Color,
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(card['icon'] as IconData,
                              color: Colors.white, size: 32),
                          const SizedBox(height: 8),
                          Text(card['value'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(card['title'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Section Historique (4 dernières factures)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Historique',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HistoriqueFacturesPage())),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoadingRecent)
              const Center(child: CircularProgressIndicator())
            else if (_recentError.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    Text(_recentError,
                        style: const TextStyle(color: Colors.red)),
                    ElevatedButton(
                        onPressed: _fetchRecentDocuments,
                        child: const Text('Réessayer'))
                  ],
                ),
              )
            else if (_recentDocuments.isEmpty)
                const Center(
                    child: Text('Aucune facture récente',
                        style: TextStyle(color: Colors.grey)))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentDocuments.length,
                  itemBuilder: (context, index) {
                    final doc = _recentDocuments[index];
                    final client = doc['client'] ?? {};
                    final clientName =
                    '${client['prenom'] ?? ''} ${client['nom'] ?? ''}'
                        .trim();
                    final date = _formatDate(doc['date_execution'] ?? '');
                    final montant = doc['montant'] ?? 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.receipt, color: Colors.black87),
                        title: Text('$date - $clientName'),
                        subtitle: Text('$montant FCFA'),
                        trailing: TextButton(
                          onPressed: () => _telechargerDocument(doc['id']),
                          child: const Text('Voir facture',
                              style: TextStyle(color: Colors.blue)),
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}