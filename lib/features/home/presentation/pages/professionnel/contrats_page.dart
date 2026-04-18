import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import './creation_contrat_bail_page.dart';
import './dio_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ContratsPage extends StatefulWidget {
  final User? user;
  const ContratsPage({super.key, this.user});

  @override
  State<ContratsPage> createState() => _ContratsPageState();
}

class _ContratsPageState extends State<ContratsPage> {
  final Dio _dio = GetIt.instance<Dio>();
  List<dynamic> _contrats = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  int _totalFactures = 0;
  int _facturesPayees = 0;
  int _facturesEnAttente = 0;
  double _montantTotal = 0;

  @override
  void initState() {
    super.initState();
    _fetchContratImmobilier();
  }

  Future<void> _fetchContratImmobilier({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }
    try {
      await handleDioRequest(context, () async {
        final response = await _dio.get(
          '/professionnel/contratBail/mes-contrat-immobilier',
          queryParameters: {'page': _currentPage, 'limit': 10},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
        if (response.statusCode == 200) {
          final data = response.data;
          final newDocuments = List<dynamic>.from(data['data'] ?? []);
          if (loadMore) {
            setState(() {
              _contrats.addAll(newDocuments);
              _hasMore = newDocuments.isNotEmpty;
            });
          } else {
            setState(() {
              _contrats = newDocuments;
              _isLoading = false;
            });
          }
          _calculerStatistiques();
        } else {
          throw Exception('Erreur serveur: ${response.statusCode}');
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  void _calculerStatistiques() {
    double montantTotal = 0;
    int payees = 0;
    int enAttente = 0;
    for (var doc in _contrats) {
      montantTotal += (doc['montant'] ?? 0).toDouble();
      double avance = (doc['avance'] ?? 0).toDouble();
      double montant = (doc['montant'] ?? 0).toDouble();
      if (avance >= montant) {
        payees++;
      } else if (avance > 0) {
        enAttente++;
      } else {
        enAttente++;
      }
    }
    setState(() {
      _totalFactures = _contrats.length;
      _montantTotal = montantTotal;
      _facturesPayees = payees;
      _facturesEnAttente = enAttente;
    });
  }

  Future<void> _loadMoreDocuments() async {
    if (_hasMore && !_isLoading) {
      setState(() => _currentPage++);
      await _fetchContratImmobilier(loadMore: true);
    }
  }

  Future<void> _refreshDocuments() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
    });
    await _fetchContratImmobilier();
  }

  String _formatDate(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(dynamic document) {
    double avance = (document['avance'] ?? 0).toDouble();
    double montant = (document['montant'] ?? 0).toDouble();
    if (avance >= montant) {
      return Colors.green;
    } else if (avance > 0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getStatusText(dynamic document) {
    double avance = (document['avance'] ?? 0).toDouble();
    double montant = (document['montant'] ?? 0).toDouble();
    if (avance >= montant) {
      return 'Payé';
    } else if (avance > 0) {
      return 'Paiement incomplet';
    } else {
      return 'Non payé';
    }
  }

  /// Affiche le modal de sélection du type de contrat
  void _showTypeContratModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nouveau contrat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Choisissez le type de contrat à créer',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Option : Contrat de bail
              _buildTypeContratCard(
                icon: Icons.home_work_outlined,
                title: 'Contrat de bail',
                description: 'Location immobilière, bail résidentiel ou commercial',
                color: Colors.indigo,
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreationContratPage(user: widget.user),
                    ),
                  );
                  if (result == true) {
                    _refreshDocuments();
                  }
                },
              ),

              const SizedBox(height: 14),

              // Option : Contrat de travail
              _buildTypeContratCard(
                icon: Icons.work_outline,
                title: 'Contrat de travail',
                description: 'CDI, CDD, temps partiel ou freelance',
                color: Colors.teal,
                onTap: () async {
                  Navigator.pop(context);
                  // TODO: Remplacer par la page dédiée au contrat de travail
                  // final result = await Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => CreationContratTravailPage(user: widget.user),
                  //   ),
                  // );
                  // if (result == true) _refreshDocuments();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contrat de travail : bientôt disponible'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Bouton Annuler
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black54,
                    side: const BorderSide(color: Colors.black12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Carte cliquable pour chaque type de contrat
  Widget _buildTypeContratCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.04),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  Future<void> _telechargerContrat(dynamic contratId) async {
    if (!mounted) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement en cours...')),
      );

      await handleDioRequest(context, () async {
        final response = await _dio.get(
          '/professionnel/contratBail/telecharger-contrat-immobilier/$contratId',
          options: Options(
            responseType: ResponseType.bytes,
            validateStatus: (status) => true,
          ),
        );

        if (response.statusCode == 200) {
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/contrat_$contratId.pdf';
          final file = File(filePath);
          await file.writeAsBytes(response.data);

          final result = await OpenFile.open(filePath);
          if (!mounted) return;

          if (result.type != ResultType.done) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Impossible d\'ouvrir: ${result.message}')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contrat téléchargé avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Erreur lors du téléchargement: ${response.statusCode}');
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToDetail(dynamic document) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  document['numero_contrat'] ?? 'Contrat',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                _detailItem('Numéro contrat', document['numero_contrat'] ?? 'N/A'),
                _detailItem(
                    'Client',
                    '${document['client']?['prenom'] ?? ''} ${document['client']?['nom'] ?? ''}'),
                _detailItem('Date', _formatDate(document['date_execution'] ?? '')),
                _detailItem('Lieu', document['lieu_execution'] ?? 'N/A'),
                _detailItem('Montant', '${document['montant']} FCFA'),
                _detailItem('Avance', '${document['avance']} FCFA'),
                _detailItem('Paiement', document['moyen_paiement'] ?? 'N/A'),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Articles',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 8),
                ...(document['items'] as List?)
                    ?.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Text("• ", style: TextStyle(fontSize: 18)),
                      Expanded(
                        child: Text(
                          '${item['designation']}  (${item['quantite']} x ${item['prix_unitaire']} FCFA)',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ))
                    .toList() ??
                    [const SizedBox()],
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Fermer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _telechargerContrat(document['id']);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.download, size: 20),
                        label: const Text('Télécharger'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contrats',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Gérez vos contrats immobiliers',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 20),

          // Statistiques
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('Total contrats', '$_totalFactures', Colors.black87)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard('Contrats payés', '$_facturesPayees', Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'Contrats en attente', '$_facturesEnAttente', Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard('Chiffre d\'affaires',
                      '${_montantTotal.toStringAsFixed(0)} FCFA', Colors.blue)),
            ],
          ),
          const SizedBox(height: 20),

          // Bouton Ajouter → ouvre le modal de sélection
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _showTypeContratModal,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Ajouter contrat'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshDocuments,
              child: _isLoading && _contrats.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty && _contrats.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(_errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _refreshDocuments,
                        child: const Text('Réessayer')),
                  ],
                ),
              )
                  : _contrats.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_outlined,
                        size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Aucun contrat',
                        style:
                        TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showTypeContratModal,
                      child: const Text('Créer un contrat'),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _contrats.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _contrats.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                          onPressed: _loadMoreDocuments,
                          child: const Text('Charger plus'),
                        ),
                      ),
                    );
                  }
                  final contrat = _contrats[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                contrat['numero_contrat'] ?? '—',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  contrat['statut'] ?? 'Inconnu',
                                  style: const TextStyle(
                                      color: Colors.white),
                                ),
                                backgroundColor: Colors.black,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${contrat['bien_adresse']} - ${contrat['bien_ville'] ?? ''}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.home,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(contrat['bien_type'] ?? ''),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  (contrat['locataires'] as List?)
                                      ?.map((l) =>
                                  "${l['prenom']} ${l['nom']}")
                                      .join(', ') ??
                                      '—',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${contrat['loyer_mensuel']} ${contrat['devise']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Début: ${_formatDate(contrat['date_debut_bail'] ?? '')}',
                                style:
                                const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () =>
                                    _telechargerContrat(contrat['id']),
                                icon: const Icon(Icons.download, size: 18),
                                label: const Text('Télécharger'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}