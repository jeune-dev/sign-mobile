import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import './client_avatar.dart';
import './dio_handler.dart';

class HistoriqueFacturesPage extends StatefulWidget {
  const HistoriqueFacturesPage({super.key});

  @override
  State<HistoriqueFacturesPage> createState() =>
      _HistoriqueFacturesPageState();
}

class _HistoriqueFacturesPageState extends State<HistoriqueFacturesPage> {
  final Dio _dio = GetIt.instance<Dio>();
  List<dynamic> _documents = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await handleDioRequest(context, () async {
        final response = await _dio.get(
          '/professionnel/document/mes-documents',
          queryParameters: {'page': page, 'limit': 10},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
        if (response.statusCode == 200) {
          final data = response.data;
          setState(() {
            _documents = List<dynamic>.from(data['data'] ?? []);
            _currentPage = data['pagination']?['currentPage'] ?? 1;
            _totalPages = data['pagination']?['totalPages'] ?? 1;
            _totalItems = data['pagination']?['totalItems'] ?? 0;
            _isLoading = false;
          });
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Historique des factures',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage,
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: () => _fetchDocuments(page: 1),
                        child: const Text('Réessayer')),
                  ],
                ),
              )
                  : _documents.isEmpty
                  ? const Center(
                child: Text('Aucune facture trouvée',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 16)),
              )
                  : ListView.builder(
                itemCount: _documents.length,
                itemBuilder: (context, index) {
                  final doc = _documents[index];
                  final client = doc['client'] ?? {};
                  final clientName =
                  '${client['prenom'] ?? ''} ${client['nom'] ?? ''}'
                      .trim();
                  final date =
                  _formatDate(doc['date_execution'] ?? '');
                  final montant = doc['montant'] ?? 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: buildClientAvatar(client),
                      title: Text('$date - $clientName'),
                      subtitle: Text('$montant FCFA'),
                      trailing: TextButton(
                        onPressed: () =>
                            _telechargerDocument(doc['id']),
                        child: const Text('Voir facture',
                            style:
                            TextStyle(color: Colors.blue)),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_totalPages > 1)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 1
                          ? () => _fetchDocuments(page: _currentPage - 1)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('Page $_currentPage / $_totalPages',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < _totalPages
                          ? () => _fetchDocuments(page: _currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}