import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import './client_avatar.dart';
import './dio_handler.dart';

class CreeFacture extends StatefulWidget {
  const CreeFacture({super.key});

  @override
  State<CreeFacture> createState() => _CreeFactureState();
}

class _CreeFactureState extends State<CreeFacture> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _rechercheController = TextEditingController();
  // Supprimé _descriptionController
  final TextEditingController _dateEcheanceController = TextEditingController();
  final TextEditingController _delaisExecutionController = TextEditingController();
  final TextEditingController _lieuExecutionController = TextEditingController();
  final TextEditingController _avanceController = TextEditingController();

  List<dynamic> _clientsTrouves = [];
  bool _isRechercheLoading = false;
  String _rechercheErreur = '';
  dynamic _clientSelectionne;
  DateTime? _dateEcheance;
  Dio? _dio;

  // Structure d'un item : type, designation, quantite, prix_unitaire
  List<Map<String, dynamic>> _items = [
    {'type': 'service', 'designation': '', 'quantite': 1, 'prix_unitaire': 0.0}
  ];

  final List<String> _moyensPaiement = [
    'ESPECES', 'ORANGE MONEY', 'WAVE', 'CARTE BANCAIRE', 'CHEQUE', 'VIREMENT',
    'AUTRE'
  ];
  String? _selectedMoyenPaiement;

  // Nouvelle variable pour la TVA
  String? _selectedTva;
  final List<String> _tvaOptions = ['0', '10', '18'];

  final List<String> _typesItem = ['produit', 'service'];

  @override
  void initState() {
    super.initState();
    _initDio();
    _lieuExecutionController.text = 'Dakar';
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

  void _ajouterItem({String type = 'service'}) {
    setState(() {
      _items.add({
        'type': type,
        'designation': '',
        'quantite': 1,
        'prix_unitaire': 0.0
      });
    });
  }

  void _supprimerItem(int index) {
    if (_items.length > 1) {
      setState(() => _items.removeAt(index));
    } else {
      // Réinitialiser le premier item
      setState(() {
        _items[0] = {'type': 'service', 'designation': '', 'quantite': 1, 'prix_unitaire': 0.0};
      });
    }
  }

  void _mettreAJourItem(int index, String champ, dynamic valeur) {
    setState(() {
      _items[index][champ] = valeur;
    });
  }

  double _calculerMontantTotal() {
    double total = 0;
    for (var item in _items) {
      double quantite = (item['type'] == 'produit'
          ? (item['quantite'] ?? 1).toDouble()
          : 1.0);
      double prixUnitaire = (item['prix_unitaire'] ?? 0.0).toDouble();
      total += quantite * prixUnitaire;
    }
    return total;
  }

  double _calculerSolde() {
    double total = _calculerMontantTotal();
    double avance = double.tryParse(_avanceController.text) ?? 0;
    return total - avance;
  }

  Future<void> _rechercherClients(String query) async {
    if (query.isEmpty) {
      setState(() {
        _clientsTrouves = [];
        _rechercheErreur = '';
      });
      return;
    }

    setState(() {
      _isRechercheLoading = true;
      _rechercheErreur = '';
    });

    try {
      await handleDioRequest(context, () async {
        final response = await _dio!.get(
          '/professionnel/client/recherche-client',
          queryParameters: {
            'nom': query,
            'prenom': query,
            'email': query,
            'carte_identite_national_num': query,
            'telephone': query,
          },
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        if (response.statusCode == 200) {
          setState(() {
            _clientsTrouves = response.data['utilisateurs'] ?? [];
            _isRechercheLoading = false;
          });
        } else {
          throw Exception('Erreur serveur: ${response.statusCode}');
        }
      });
    } catch (e) {
      setState(() {
        _rechercheErreur = 'Erreur: $e';
        _isRechercheLoading = false;
        _clientsTrouves = [];
      });
    }
  }

  void _selectionnerClient(dynamic client) {
    setState(() {
      _clientSelectionne = client;
      _clientsTrouves = [];
      _rechercheController.clear();
    });
  }

  void _annulerSelectionClient() => setState(() => _clientSelectionne = null);

  Future<void> _selectDateEcheance(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateEcheance = picked;
        _dateEcheanceController.text =
        "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _soumettreFacture() async {
    if (_formKey.currentState!.validate()) {
      if (_clientSelectionne == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veuillez sélectionner un client'),
              backgroundColor: Colors.red),
        );
        return;
      }
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item['designation'] == null ||
            item['designation']!.toString().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Veuillez remplir la désignation de l\'article ${i + 1}'),
                backgroundColor: Colors.red),
          );
          return;
        }
        if (item['type'] == 'produit' && (item['quantite'] ?? 0) <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'La quantité de l\'article ${i + 1} doit être > 0'),
                backgroundColor: Colors.red),
          );
          return;
        }
        if ((item['prix_unitaire'] ?? 0) <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Le prix unitaire de l\'article ${i + 1} doit être > 0'),
                backgroundColor: Colors.red),
          );
          return;
        }
      }
      try {
        await handleDioRequest(context, () async {
          final itemsPayload = _items.map((item) {
            return {
              'designation': item['designation'],
              'quantite': item['type'] == 'produit' ? item['quantite'] : 1,
              'prix_unitaire': item['prix_unitaire'],
            };
          }).toList();

          final nouvelleFacture = {
            'clientId': _clientSelectionne['id'],
            'delais_execution': _delaisExecutionController.text,
            'date_execution': _dateEcheance?.toIso8601String(),
            'avance': double.tryParse(_avanceController.text) ?? 0,
            'lieu_execution': _lieuExecutionController.text,
            'moyen_paiement': _selectedMoyenPaiement ?? 'ESPECES',
            'items': itemsPayload,
            'montant_total': _calculerMontantTotal(),
            'solde': _calculerSolde(),
            // Ajout de la TVA
            'tva': int.parse(_selectedTva ?? '0'), // envoi en pourcentage
          };
          final response = await _dio!.post(
            '/professionnel/document/creer-document',
            data: nouvelleFacture,
            options: Options(headers: {'Content-Type': 'application/json'}),
          );
          if (response.statusCode == 201 || response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Facture créée avec succès!'),
                  backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else {
            throw Exception('Erreur serveur: ${response.statusCode}');
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double total = _calculerMontantTotal();
    final double solde = _calculerSolde();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Nouvelle Facture',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Créer une nouvelle facture',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Remplissez les informations',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),

              // Client
              const Text('Client *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_clientSelectionne != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green)),
                  child: Row(
                    children: [
                      buildClientAvatar(_clientSelectionne, radius: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${_clientSelectionne['prenom']} ${_clientSelectionne['nom']}',
                                style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                            Text(_clientSelectionne['email'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text(_clientSelectionne['telephone'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: _annulerSelectionClient),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _rechercheController,
                      decoration: InputDecoration(
                        labelText: 'Rechercher un client *',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isRechercheLoading
                            ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                            CircularProgressIndicator(strokeWidth: 2))
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (value) =>
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (value == _rechercheController.text) {
                              _rechercherClients(value);
                            }
                          }),
                    ),
                    if (_rechercheErreur.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_rechercheErreur,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    if (_clientsTrouves.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8)),
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _clientsTrouves.length,
                          itemBuilder: (context, index) {
                            final client = _clientsTrouves[index];
                            return ListTile(
                              leading: buildClientAvatar(client, radius: 20),
                              title:
                              Text('${client['prenom']} ${client['nom']}'),
                              subtitle: Text(client['email'] ?? ''),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 16),
                              onTap: () => _selectionnerClient(client),
                            );
                          },
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 24),

              // Articles
              const Text('Articles *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Ajoutez des produits ou services',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final bool isProduit = item['type'] == 'produit';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête de la ligne : type + bouton supprimer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: DropdownButton<String>(
                                    value: item['type'],
                                    isDense: true,
                                    underline: const SizedBox(),
                                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                                    items: _typesItem.map((type) {
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Text(
                                          type == 'produit' ? '📦 Produit' : '🛠️ Service',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _mettreAJourItem(index, 'type', value);
                                        if (value == 'service') {
                                          _mettreAJourItem(index, 'quantite', 1);
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ),
                              if (_items.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _supprimerItem(index),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Désignation
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Désignation *',
                              hintText: isProduit ? 'Ex: Ordinateur portable' : 'Ex: Prestation de conseil',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            initialValue: item['designation'],
                            onChanged: (value) =>
                                _mettreAJourItem(index, 'designation', value),
                            validator: (value) => value == null ||
                                value.isEmpty
                                ? 'Veuillez entrer une désignation'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Ligne quantité (seulement pour produit) et prix
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isProduit)
                                Expanded(
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Quantité *',
                                      hintText: 'Ex: 2',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    ),
                                    keyboardType: TextInputType.number,
                                    initialValue: item['quantite'].toString(),
                                    onChanged: (value) {
                                      int? quantite = int.tryParse(value);
                                      if (quantite != null && quantite > 0) {
                                        _mettreAJourItem(
                                            index, 'quantite', quantite);
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Requis';
                                      }
                                      final quantite = int.tryParse(value);
                                      if (quantite == null || quantite <= 0) {
                                        return 'Quantité invalide';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              if (isProduit) const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Prix unitaire (FCFA) *',
                                    hintText: 'Ex: 5000',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  ),
                                  keyboardType: TextInputType.number,
                                  initialValue: item['prix_unitaire'].toString(),
                                  onChanged: (value) {
                                    double? prix = double.tryParse(value);
                                    if (prix != null && prix >= 0) {
                                      _mettreAJourItem(
                                          index, 'prix_unitaire', prix);
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Requis';
                                    }
                                    final prix = double.tryParse(value);
                                    if (prix == null || prix < 0) {
                                      return 'Prix invalide';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Affichage du sous-total
                          if (item['prix_unitaire'] > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Sous-total: ',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    '${((isProduit ? item['quantite'] : 1) * item['prix_unitaire']).toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Boutons pour ajouter produit ou service
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _ajouterItem(type: 'produit'),
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('Ajouter produit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _ajouterItem(type: 'service'),
                      icon: const Icon(Icons.build_outlined),
                      label: const Text('Ajouter service'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.orange.shade300),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Récapitulatif financier
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Récapitulatif',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Montant total:'),
                          Text('${total.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      const Text('Avance',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _avanceController,
                        decoration: InputDecoration(
                          labelText: 'Montant de l\'avance (FCFA)',
                          prefixIcon: const Icon(Icons.payment),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setState(() {}),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final avance = double.tryParse(value);
                            if (avance == null || avance < 0) {
                              return 'Avance invalide';
                            }
                            if (avance > total) {
                              return 'L\'avance ne peut pas dépasser le montant total';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Solde à payer:'),
                          Text(
                            '${solde.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: solde > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Délais d'exécution
              const Text('Délais d\'exécution *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _delaisExecutionController,
                decoration: InputDecoration(
                  labelText: 'Ex: 2 jours',
                  prefixIcon: const Icon(Icons.timer),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez spécifier les délais'
                    : null,
              ),

              const SizedBox(height: 16),

              // Lieu d'exécution
              const Text('Lieu d\'exécution *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lieuExecutionController,
                decoration: InputDecoration(
                  labelText: 'Lieu',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez spécifier le lieu'
                    : null,
              ),

              const SizedBox(height: 16),

              // Moyen de paiement
              const Text('Moyen de paiement *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMoyenPaiement,
                decoration: InputDecoration(
                  labelText: 'Sélectionnez',
                  prefixIcon: const Icon(Icons.payment),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: _moyensPaiement
                    .map((moyen) => DropdownMenuItem(
                    value: moyen, child: Text(moyen)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedMoyenPaiement = value),
                validator: (value) => value == null
                    ? 'Veuillez sélectionner un moyen de paiement'
                    : null,
              ),

              const SizedBox(height: 16),

              // Date d'échéance
              const Text('Date d\'échéance *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateEcheanceController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date d\'échéance',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () => _selectDateEcheance(context),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez sélectionner une date'
                    : null,
              ),

              const SizedBox(height: 16),

              // TVA (remplace Description)
              const Text('TVA (%) *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTva,
                decoration: InputDecoration(
                  labelText: 'Sélectionnez le taux',
                  prefixIcon: const Icon(Icons.percent),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: _tvaOptions
                    .map((tva) => DropdownMenuItem(
                    value: tva, child: Text('$tva %')))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedTva = value),
                validator: (value) => value == null
                    ? 'Veuillez sélectionner un taux'
                    : null,
              ),

              const SizedBox(height: 32),

              // Bouton de création
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _soumettreFacture,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Créer la facture',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    // _descriptionController supprimé
    _dateEcheanceController.dispose();
    _delaisExecutionController.dispose();
    _lieuExecutionController.dispose();
    _avanceController.dispose();
    super.dispose();
  }
}