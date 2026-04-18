import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import './cree_facture_page.dart';
import './dio_handler.dart';

class FacturesPage extends StatefulWidget {
  final User? user;
  const FacturesPage({super.key, this.user});

  @override
  State<FacturesPage> createState() => _FacturesPageState();
}

class _FacturesPageState extends State<FacturesPage> {
  final Dio _dio = GetIt.instance<Dio>();
  List<dynamic> _documents = [];
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
    _fetchDocuments();
  }

  Future<void> _fetchDocuments({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }
    try {
      await handleDioRequest(context, () async {
        final response = await _dio.get(
          '/professionnel/document/mes-documents',
          queryParameters: {'page': _currentPage, 'limit': 10},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
        if (response.statusCode == 200) {
          final data = response.data;
          final newDocuments = List<dynamic>.from(data['data'] ?? []);
          if (loadMore) {
            setState(() {
              _documents.addAll(newDocuments);
              _hasMore = newDocuments.isNotEmpty;
            });
          } else {
            setState(() {
              _documents = newDocuments;
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
    for (var doc in _documents) {
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
      _totalFactures = _documents.length;
      _montantTotal = montantTotal;
      _facturesPayees = payees;
      _facturesEnAttente = enAttente;
    });
  }

  Future<void> _loadMoreDocuments() async {
    if (_hasMore && !_isLoading) {
      setState(() => _currentPage++);
      await _fetchDocuments(loadMore: true);
    }
  }

  Future<void> _refreshDocuments() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
    });
    await _fetchDocuments();
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
      return 'Payée';
    } else if (avance > 0) {
      return 'Paiement incomplet';
    } else {
      return 'Non payée';
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
                  document['numero_facture'] ?? 'Facture',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                _detailItem('Numéro', document['numero_facture'] ?? 'N/A'),
                _detailItem(
                    'Client',
                    '${document['client']?['prenom'] ?? ''} ${document['client']?['nom'] ?? ''}'),
                _detailItem('Date', _formatDate(document['date_execution'])),
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
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black),
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
                          _telechargerDocument(document['id']);
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
            Text(title,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
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
          const Text('Factures',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Gérez vos factures',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 20),

          // Statistiques
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('Total', '$_totalFactures', Colors.black87)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard('Payées', '$_facturesPayees', Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'En attente', '$_facturesEnAttente', Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard('Chiffre d\'affaire',
                      '${_montantTotal.toStringAsFixed(0)} FCFA', Colors.blue)),
            ],
          ),
          const SizedBox(height: 20),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreeFacture())),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Ajouter facture'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshDocuments,
              child: _isLoading && _documents.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty && _documents.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error,
                        color: Colors.red, size: 64),
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
                  : _documents.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_outlined,
                        size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Aucune facture',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CreeFacture())),
                      child: const Text('Créer une facture'),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount:
                _documents.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _documents.length) {
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
                  final document = _documents[index];
                  final statusColor = _getStatusColor(document);
                  final statusText = _getStatusText(document);
                  final client = document['client'];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        document[
                                        'numero_facture'] ??
                                            'Sans numéro',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                            FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Client: ${client?['prenom'] ?? ''} ${client?['nom'] ?? ''}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(statusText,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight.bold)),
                                backgroundColor: statusColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(_formatDate(
                                  document['date_execution'])),
                              const Spacer(),
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(document['lieu_execution'] ??
                                  ''),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.attach_money,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${document['montant']} FCFA',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                              const Spacer(),
                              const Icon(Icons.payment,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(document['moyen_paiement'] ??
                                  ''),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    _telechargerDocument(
                                        document['id']),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.download, size: 16),
                                    SizedBox(width: 4),
                                    Text('Télécharger'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () =>
                                    _navigateToDetail(document),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.visibility,
                                        size: 16),
                                    SizedBox(width: 4),
                                    Text('Voir plus'),
                                  ],
                                ),
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