import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import 'package:sign_application/features/client/presentation/bloc/client_bloc.dart';
import 'package:sign_application/features/client/presentation/bloc/client_event.dart';
import 'package:sign_application/features/client/presentation/bloc/client_state.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_bloc.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_event.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_state.dart';
import 'package:sign_application/features/client/presentation/widgets/client_avatar.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/core/widgets/confirmation_dialog.dart';

class CreeFacture extends StatefulWidget {
  const CreeFacture({super.key});

  @override
  State<CreeFacture> createState() => _CreeFactureState();
}

class _CreeFactureState extends State<CreeFacture> {
  final _formKey = GlobalKey<FormState>();
  final _rechercheController = TextEditingController();
  final _dateEcheanceController = TextEditingController();
  final _delaisExecutionController = TextEditingController();
  final _lieuExecutionController = TextEditingController();
  final _avanceController = TextEditingController();
  final _montantPayeController = TextEditingController();
  bool _avanceActif = false;
  bool _montantPayeActif = false;

  List<Client> _clientsTrouves = [];
  Client? _clientSelectionne;
  DateTime? _dateEcheance;

  List<Map<String, dynamic>> _items = [
    {'type': 'service', 'designation': '', 'quantite': 1, 'prix_unitaire': 0.0}
  ];

  final List<String> _moyensPaiement = ['ESPECES', 'ORANGE MONEY', 'WAVE', 'CARTE BANCAIRE', 'CHEQUE', 'VIREMENT', 'AUTRE'];
  String? _selectedMoyenPaiement;
  String? _selectedTva;
  final List<String> _tvaOptions = ['0', '10', '18'];
  final List<String> _typesItem = ['produit', 'service'];

  @override
  void initState() {
    super.initState();
    _lieuExecutionController.text = 'Dakar';
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    _dateEcheanceController.dispose();
    _delaisExecutionController.dispose();
    _lieuExecutionController.dispose();
    _avanceController.dispose();
    _montantPayeController.dispose();
    super.dispose();
  }

  void _ajouterItem({String type = 'service'}) {
    setState(() => _items.add({'type': type, 'designation': '', 'quantite': 1, 'prix_unitaire': 0.0}));
  }

  Future<void> _supprimerItem(int index) async {
    if (_items.length > 1) {
      final confirmed = await showConfirmationDialog(
        context,
        title: 'Supprimer la ligne',
        message: 'Cette ligne sera définitivement retirée de la facture.',
        confirmLabel: 'Supprimer',
      );
      if (confirmed && mounted) setState(() => _items.removeAt(index));
    } else {
      setState(() => _items[0] = {'type': 'service', 'designation': '', 'quantite': 1, 'prix_unitaire': 0.0});
    }
  }

  void _mettreAJourItem(int index, String champ, dynamic valeur) {
    setState(() => _items[index][champ] = valeur);
  }

  double _calculerMontantTotal() {
    double total = 0;
    for (var item in _items) {
      final q = item['type'] == 'produit' ? (item['quantite'] ?? 1).toDouble() : 1.0;
      total += q * (item['prix_unitaire'] ?? 0.0).toDouble();
    }
    return total;
  }

  double _calculerSolde() {
    final paye = (double.tryParse(_avanceController.text) ?? 0) +
        (double.tryParse(_montantPayeController.text) ?? 0);
    return _calculerMontantTotal() - paye;
  }

  void _rechercherClients(String query) {
    if (query.isEmpty) {
      setState(() => _clientsTrouves = []);
      return;
    }
    context.read<ClientBloc>().add(RechercherClientsEvent(query));
  }

  void _selectionnerClient(Client client) {
    setState(() {
      _clientSelectionne = client;
      _clientsTrouves = [];
      _rechercheController.clear();
    });
  }

  Future<void> _selectDateEcheance() async {
    final picked = await showDatePicker(
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

  void _soumettreFacture() {
    if (!_formKey.currentState!.validate()) return;
    if (_clientSelectionne == null) {
      showToast(context, 'Champ requis', 'Veuillez sélectionner un client', ToastificationType.error);
      return;
    }
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if ((item['designation'] ?? '').toString().isEmpty) {
        showToast(context, 'Article incomplet', 'Veuillez remplir la désignation de l\'article ${i + 1}', ToastificationType.error);
        return;
      }
      if ((item['prix_unitaire'] ?? 0) <= 0) {
        showToast(context, 'Prix invalide', 'Le prix unitaire de l\'article ${i + 1} doit être supérieur à 0', ToastificationType.error);
        return;
      }
    }

    final payload = {
      'clientId': _clientSelectionne!.id,
      'delais_execution': _delaisExecutionController.text,
      'date_execution': _dateEcheance?.toIso8601String(),
      'avance': double.tryParse(_avanceController.text) ?? 0,
      'montant_paye': double.tryParse(_montantPayeController.text) ?? 0,
      'lieu_execution': _lieuExecutionController.text,
      'moyen_paiement': _selectedMoyenPaiement ?? 'ESPECES',
      'tva': int.parse(_selectedTva ?? '0'),
      'items': _items.map((item) => {
            'designation': item['designation'],
            'quantite': item['type'] == 'produit' ? item['quantite'] : 1,
            'prix_unitaire': item['prix_unitaire'],
          }).toList(),
      'montant_total': _calculerMontantTotal(),
      'solde': _calculerSolde(),
    };

    context.read<FactureBloc>().add(CreerFactureEvent(payload));
  }

  @override
  Widget build(BuildContext context) {
    final double total = _calculerMontantTotal();
    final double solde = _calculerSolde();

    return BlocListener<FactureBloc, FactureState>(
      listener: (context, state) {
        if (state is FactureSuccess) {
          showToast(context, 'Facture créée', 'La facture a été créée avec succès.', ToastificationType.success);
          Navigator.pop(context);
        }
        if (state is FactureError) {
          showToast(context, 'Erreur', state.message, ToastificationType.error);
        }
      },
      child: BlocListener<ClientBloc, ClientState>(
        listener: (context, state) {
          if (state is ClientsRechercheLoaded) {
            setState(() => _clientsTrouves = state.clients);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Nouvelle Facture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            centerTitle: true,
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context), tooltip: 'Retour'),
          ),
          body: BlocBuilder<FactureBloc, FactureState>(
            builder: (context, factureState) {
              final isLoading = factureState is FactureLoading;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Créer une nouvelle facture', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Remplissez les informations', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 24),

                      // CLIENT
                      const Text('Client *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_clientSelectionne != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              buildClientAvatar({'prenom': _clientSelectionne!.prenom, 'nom': _clientSelectionne!.nom}, radius: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${_clientSelectionne!.prenom} ${_clientSelectionne!.nom}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(_clientSelectionne!.email ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text(_clientSelectionne!.telephone ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => setState(() => _clientSelectionne = null),
                                tooltip: 'Retirer le client',
                              ),
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (v) => Future.delayed(
                                const Duration(milliseconds: 500),
                                () { if (v == _rechercheController.text) _rechercherClients(v); },
                              ),
                            ),
                            if (_clientsTrouves.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _clientsTrouves.length,
                                  itemBuilder: (context, index) {
                                    final c = _clientsTrouves[index];
                                    return ListTile(
                                      leading: buildClientAvatar({'prenom': c.prenom, 'nom': c.nom}, radius: 20),
                                      title: Text('${c.prenom} ${c.nom}'),
                                      subtitle: Text(c.email ?? ''),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                      onTap: () => _selectionnerClient(c),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      // ARTICLES
                      const Text('Articles *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Ajoutez des produits ou services', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                                          child: DropdownButton<String>(
                                            value: item['type'],
                                            isDense: true,
                                            underline: const SizedBox(),
                                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                                            items: _typesItem.map((type) => DropdownMenuItem(
                                              value: type,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(type == 'produit' ? Icons.inventory_2_outlined : Icons.build_outlined, size: 14),
                                                  const SizedBox(width: 6),
                                                  Text(type == 'produit' ? 'Produit' : 'Service', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                                ],
                                              ),
                                            )).toList(),
                                            onChanged: (v) {
                                              if (v != null) {
                                                _mettreAJourItem(index, 'type', v);
                                                if (v == 'service') _mettreAJourItem(index, 'quantite', 1);
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
                                          tooltip: 'Supprimer cet article',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Désignation *',
                                      hintText: isProduit ? 'Ex: Ordinateur portable' : 'Ex: Prestation de conseil',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    ),
                                    initialValue: item['designation'],
                                    onChanged: (v) => _mettreAJourItem(index, 'designation', v),
                                    validator: (v) => v == null || v.isEmpty ? 'Veuillez entrer une désignation' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (isProduit) ...[
                                        Expanded(
                                          child: TextFormField(
                                            decoration: InputDecoration(
                                              labelText: 'Quantité *',
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                            ),
                                            keyboardType: TextInputType.number,
                                            initialValue: item['quantite'].toString(),
                                            onChanged: (v) {
                                              final q = int.tryParse(v);
                                              if (q != null && q > 0) _mettreAJourItem(index, 'quantite', q);
                                            },
                                            validator: (v) {
                                              if (v == null || v.isEmpty) return 'Requis';
                                              final q = int.tryParse(v);
                                              if (q == null || q <= 0) return 'Quantité invalide';
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      Expanded(
                                        child: TextFormField(
                                          decoration: InputDecoration(
                                            labelText: 'Prix unitaire (FCFA) *',
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                          ),
                                          keyboardType: TextInputType.number,
                                          initialValue: item['prix_unitaire'].toString(),
                                          onChanged: (v) {
                                            final p = double.tryParse(v);
                                            if (p != null && p >= 0) _mettreAJourItem(index, 'prix_unitaire', p);
                                          },
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return 'Requis';
                                            final p = double.tryParse(v);
                                            if (p == null || p < 0) return 'Prix invalide';
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((item['prix_unitaire'] ?? 0) > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text('Sous-total: ', style: TextStyle(color: Colors.grey[600])),
                                          Text(
                                            '${((isProduit ? item['quantite'] : 1) * item['prix_unitaire']).toStringAsFixed(0)} FCFA',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
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

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _ajouterItem(type: 'produit'),
                              icon: const Icon(Icons.inventory_2_outlined),
                              label: const Text('Ajouter produit'),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: Colors.blue.shade300)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _ajouterItem(type: 'service'),
                              icon: const Icon(Icons.build_outlined),
                              label: const Text('Ajouter service'),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: Colors.orange.shade300)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // RÉCAPITULATIF
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Récapitulatif', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Montant total:'),
                                  Text('${total.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Divider(color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              const Text('Paiement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _avanceController,
                                enabled: !_montantPayeActif,
                                decoration: InputDecoration(
                                  labelText: 'Avance (FCFA)',
                                  prefixIcon: const Icon(Icons.payment),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  filled: _montantPayeActif,
                                  fillColor: _montantPayeActif ? Colors.grey[100] : null,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                onChanged: (v) => setState(() {
                                  _avanceActif = v.isNotEmpty;
                                  if (v.isNotEmpty) _montantPayeController.clear();
                                }),
                                validator: (v) {
                                  if (v != null && v.isNotEmpty) {
                                    final a = double.tryParse(v);
                                    if (a == null || a < 0) return 'Avance invalide';
                                    if (a > total) return 'L\'avance ne peut pas dépasser le montant total';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('OU', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _montantPayeController,
                                enabled: !_avanceActif,
                                decoration: InputDecoration(
                                  labelText: 'Montant payé (FCFA)',
                                  prefixIcon: const Icon(Icons.check_circle_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  filled: _avanceActif,
                                  fillColor: _avanceActif ? Colors.grey[100] : null,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                onChanged: (v) => setState(() {
                                  _montantPayeActif = v.isNotEmpty;
                                  if (v.isNotEmpty) _avanceController.clear();
                                }),
                                validator: (v) {
                                  if (v != null && v.isNotEmpty) {
                                    final a = double.tryParse(v);
                                    if (a == null || a < 0) return 'Montant invalide';
                                    if (a > total) return 'Le montant payé ne peut pas dépasser le total';
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
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: solde > 0 ? Colors.red : Colors.green),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text('Délais d\'exécution *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _delaisExecutionController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Ex: 2 (jours)',
                          prefixIcon: const Icon(Icons.timer),
                          suffixText: 'jours',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Veuillez spécifier les délais' : null,
                      ),

                      const SizedBox(height: 16),

                      const Text('Lieu d\'exécution *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _lieuExecutionController,
                        decoration: InputDecoration(
                          labelText: 'Lieu',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Veuillez spécifier le lieu' : null,
                      ),

                      const SizedBox(height: 16),

                      const Text('Moyen de paiement *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedMoyenPaiement,
                        decoration: InputDecoration(
                          labelText: 'Sélectionnez',
                          prefixIcon: const Icon(Icons.payment),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        items: _moyensPaiement.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (v) => setState(() => _selectedMoyenPaiement = v),
                        validator: (v) => v == null ? 'Veuillez sélectionner un moyen de paiement' : null,
                      ),

                      const SizedBox(height: 16),

                      const Text('Date d\'échéance *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dateEcheanceController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Date d\'échéance',
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: IconButton(icon: const Icon(Icons.date_range), onPressed: _selectDateEcheance, tooltip: 'Choisir une date'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Veuillez sélectionner une date' : null,
                      ),

                      const SizedBox(height: 16),

                      const Text('TVA (%) *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedTva,
                        decoration: InputDecoration(
                          labelText: 'Sélectionnez le taux',
                          prefixIcon: const Icon(Icons.percent),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        items: _tvaOptions.map((t) => DropdownMenuItem(value: t, child: Text('$t %'))).toList(),
                        onChanged: (v) => setState(() => _selectedTva = v),
                        validator: (v) => v == null ? 'Veuillez sélectionner un taux' : null,
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _soumettreFacture,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Créer la facture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
