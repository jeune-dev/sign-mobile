import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import './ajouter_client_page.dart';
import './client_avatar.dart';
import './dio_handler.dart';

class ClientsPage extends StatefulWidget {
  final User? user;
  const ClientsPage({super.key, this.user});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  late Future<Map<String, dynamic>> _futureClients;
  Dio? _dio;
  bool _isLoading = false;
  int _totalClients = 0;

  @override
  void initState() {
    super.initState();
    _initDio();
    _futureClients = _fetchClients();
  }

  void _initDio() {
    try {
      _dio = GetIt.instance<Dio>();
    } catch (e) {
      _dio = Dio(BaseOptions(
        baseUrl: 'https://sign-backend-v1.onrender.com',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
    }
  }

  Future<Map<String, dynamic>> _fetchClients() async {
    if (_dio == null) _initDio();
    setState(() => _isLoading = true);
    try {
      return await handleDioRequest(context, () async {
        final response = await _dio!.get(
          '/professionnel/client/liste-clients',
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
        if (response.statusCode == 200) {
          final data = response.data;
          setState(() {
            _totalClients = data['pagination']?['totalClients'] ??
                (data['utilisateurs']?.length ?? 0);
          });
          return data;
        } else {
          throw Exception('Erreur serveur: ${response.statusCode}');
        }
      });
    } catch (e) {
      setState(() => _totalClients = 0);
      throw Exception('Échec de la connexion: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _detailItem(IconData icon, String title, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.black),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  value.toString(),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClientDetails(BuildContext context, dynamic client) {
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
              )
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.black,
                  child: Text(
                    client['prenom'][0],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${client['prenom']} ${client['nom']}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(height: 24),
                _detailItem(
                    Icons.email_outlined, 'Email', client['email']),
                _detailItem(
                    Icons.phone_outlined, 'Téléphone', client['telephone']),
                _detailItem(
                    Icons.location_on_outlined, 'Adresse', client['adresse']),
                _detailItem(
                    Icons.verified_user_outlined, 'Statut', client['statut']),
                if (client['createdAt'] != null)
                  _detailItem(
                    Icons.calendar_today_outlined,
                    'Inscrit le',
                    DateTime.parse(client['createdAt'])
                        .toLocal()
                        .toString()
                        .split(' ')[0],
                  ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          const Text('Les clients',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Gérez vos clients et leurs contrats',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 20),

          // Statistique du nombre de clients
          Card(
            color: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total clients',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('$_totalClients',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AjouterClientPage())),
                icon: const Icon(Icons.person_add, size: 20),
                label: const Text('Ajouter client'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _futureClients = _fetchClients()),
                icon: _isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 20),
                label: Text(_isLoading ? 'Chargement...' : 'Actualiser'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _futureClients,
              builder: (context, snapshot) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 50),
                        const SizedBox(height: 16),
                        Text('Erreur: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: () => setState(
                                    () => _futureClients = _fetchClients()),
                            child: const Text('Réessayer')),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('Aucune donnée'));
                }
                final utilisateurs = snapshot.data!['utilisateurs'] ?? [];
                if (utilisateurs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Aucun client trouvé',
                            style:
                            TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: utilisateurs.length,
                  itemBuilder: (context, index) {
                    final client = utilisateurs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: buildClientAvatar(client),
                        title: Text(
                            '${client['prenom'] ?? ''} ${client['nom'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (client['email'] != null)
                              Text('Email: ${client['email']}'),
                            if (client['carte_identite_national_num'] != null)
                              Text(
                                  'CIN: ${client['carte_identite_national_num']}'),
                          ],
                        ),
                        trailing: const Chip(
                            label: Text('Voir', style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.black87),
                        onTap: () => _showClientDetails(context, client),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}