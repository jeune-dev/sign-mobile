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

  // ── Client non inscrit (saisie manuelle) ────────────────────────────────
  bool _modeClientManuel = false;
  final _clientManuelNomController = TextEditingController();
  final _clientManuelPrenomController = TextEditingController();
  final _clientManuelEmailController = TextEditingController();
  final _clientManuelTelephoneController = TextEditingController();
  final _clientManuelAdresseController = TextEditingController();

  final List<Map<String, dynamic>> _items = [
    {'type': 'service', 'designation': '', 'quantite': 1, 'prix_unitaire': 0.0}
  ];

  final List<String> _moyensPaiement = ['ESPECES', 'ORANGE MONEY', 'WAVE', 'CARTE BANCAIRE', 'CHEQUE', 'VIREMENT', 'AUTRE'];
  String? _selectedMoyenPaiement;
  String? _selectedTva;
  final List<String> _tvaOptions = ['0', '10', '18'];

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
    _clientManuelNomController.dispose();
    _clientManuelPrenomController.dispose();
    _clientManuelEmailController.dispose();
    _clientManuelTelephoneController.dispose();
    _clientManuelAdresseController.dispose();
    super.dispose();
  }

  void _toggleModeClientManuel() {
    setState(() {
      _modeClientManuel = !_modeClientManuel;
      _clientSelectionne = null;
      _clientsTrouves = [];
      _rechercheController.clear();
    });
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

  /// Sélecteur Service/Produit — deux boutons pill bien visibles, pour que
  /// l'utilisateur perçoive immédiatement qu'il peut choisir (contrairement
  /// à l'ancien dropdown discret que personne ne remarquait).
  Widget _typeItemToggle({required String selected, required ValueChanged<String> onChanged}) {
    Widget pill(String type, IconData icon, String label) {
      final bool active = selected == type;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: active ? Colors.white : Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          pill('service', Icons.build_outlined, 'Service'),
          pill('produit', Icons.inventory_2_outlined, 'Produit'),
        ],
      ),
    );
  }

  void _soumettreFacture() {
    if (!_formKey.currentState!.validate()) return;

    if (_modeClientManuel) {
      if (_clientManuelNomController.text.trim().isEmpty ||
          _clientManuelPrenomController.text.trim().isEmpty ||
          _clientManuelEmailController.text.trim().isEmpty) {
        showToast(context, 'Champ requis', 'Nom, prénom et email du client sont requis', ToastificationType.error);
        return;
      }
    } else if (_clientSelectionne == null) {
      showToast(context, 'Champ requis', 'Veuillez sélectionner un client', ToastificationType.error);
      return;
    }

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if ((item['designation'] ?? '').toString().isEmpty) {
        showToast(context, 'Produit/Service incomplet', 'Veuillez remplir la désignation de la ligne ${i + 1}', ToastificationType.error);
        return;
      }
      if ((item['prix_unitaire'] ?? 0) <= 0) {
        showToast(context, 'Prix invalide', 'Le prix unitaire de la ligne ${i + 1} doit être supérieur à 0', ToastificationType.error);
        return;
      }
    }

    final items = _items.map((item) => {
          'designation': item['designation'],
          'quantite': item['type'] == 'produit' ? item['quantite'] : 1,
          'prix_unitaire': item['prix_unitaire'],
        }).toList();

    if (_modeClientManuel) {
      final payload = {
        'client': {
          'nom': _clientManuelNomController.text.trim(),
          'prenom': _clientManuelPrenomController.text.trim(),
          'email': _clientManuelEmailController.text.trim(),
          'telephone': _clientManuelTelephoneController.text.trim(),
          'adresse': _clientManuelAdresseController.text.trim(),
        },
        'delais_execution': _delaisExecutionController.text,
        'date_execution': _dateEcheance?.toIso8601String(),
        'avance': double.tryParse(_avanceController.text) ?? 0,
        'montant_paye': double.tryParse(_montantPayeController.text) ?? 0,
        'lieu_execution': _lieuExecutionController.text,
        'moyen_paiement': _selectedMoyenPaiement ?? 'ESPECES',
        'tva': int.parse(_selectedTva ?? '0'),
        'items': items,
      };
      context.read<FactureBloc>().add(CreerFactureClientManuelEvent(payload));
      return;
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
      'items': items,
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
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white), onPressed: () => Navigator.pop(context), tooltip: 'Retour'),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Client *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: _toggleModeClientManuel,
                            icon: Icon(_modeClientManuel ? Icons.search : Icons.person_add_alt_1, size: 18),
                            label: Text(_modeClientManuel ? 'Client inscrit' : 'Client non inscrit'),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_modeClientManuel)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Client non inscrit sur l'application — ses informations seront utilisées uniquement pour cette facture.",
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _clientManuelPrenomController,
                                      decoration: const InputDecoration(labelText: 'Prénom *', isDense: true, border: OutlineInputBorder()),
                                      validator: (v) => _modeClientManuel && (v == null || v.trim().isEmpty) ? 'Requis' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _clientManuelNomController,
                                      decoration: const InputDecoration(labelText: 'Nom *', isDense: true, border: OutlineInputBorder()),
                                      validator: (v) => _modeClientManuel && (v == null || v.trim().isEmpty) ? 'Requis' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _clientManuelEmailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(labelText: 'Email *', isDense: true, border: OutlineInputBorder()),
                                validator: (v) {
                                  if (!_modeClientManuel) return null;
                                  if (v == null || v.trim().isEmpty) return 'Requis';
                                  if (!v.contains('@')) return 'Email invalide';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _clientManuelTelephoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(labelText: 'Téléphone', isDense: true, border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _clientManuelAdresseController,
                                decoration: const InputDecoration(labelText: 'Adresse', isDense: true, border: OutlineInputBorder()),
                              ),
                            ],
                          ),
                        )
                      else if (_clientSelectionne != null)
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

                      // PRODUITS/SERVICES
                      const Text('Produit/Service *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                        child: _typeItemToggle(
                                          selected: item['type'],
                                          onChanged: (v) {
                                            _mettreAJourItem(index, 'type', v);
                                            if (v == 'service') _mettreAJourItem(index, 'quantite', 1);
                                          },
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
                                      filled: true,
                                  fillColor: const Color(0xFFF8F8FA),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black87, width: 1.5)),
                                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
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
                                              filled: true,
                                  fillColor: const Color(0xFFF8F8FA),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black87, width: 1.5)),
                                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
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
                                            filled: true,
                                  fillColor: const Color(0xFFF8F8FA),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black87, width: 1.5)),
                                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
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
                                  filled: _montantPayeActif,
                                  fillColor: _montantPayeActif ? Colors.grey[100] : const Color(0xFFF8F8FA),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black87, width: 1.5)),
                                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                                    // Le plafond réel (montant TTC, TVA incluse) est
                                    // vérifié côté serveur — le message d'erreur
                                    // affiché vient du backend, pas d'un seuil
                                    // recalculé ici (qui ignorerait la TVA).
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
                                  filled: _avanceActif,
                                  fillColor: _avanceActif ? Colors.grey[100] : const Color(0xFFF8F8FA),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black87, width: 1.5)),
                                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                                    // Le plafond réel (montant TTC, TVA incluse) est
                                    // vérifié côté serveur — le message d'erreur
                                    // affiché vient du backend, pas d'un seuil
                                    // recalculé ici (qui ignorerait la TVA).
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
                          filled: true,
                                  fillColor: const Color(0xFFF8F8FA),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black87, width: 1.5)),
                                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
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
                          filled: true,
                                  fillColor: const Color(0xFFF8F8FA),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black87, width: 1.5)),
                                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Veuillez spécifier le lieu' : null,
                      ),

                      const SizedBox(height: 16),

                      const Text('Moyen de paiement *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMoyenPaiement,
                        decoration: InputDecoration(
                          labelText: 'Sélectionnez',
                          prefixIcon: const Icon(Icons.payment),
                          filled: true,
                                  fillColor: const Color(0xFFF8F8FA),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black87, width: 1.5)),
                                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
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
                          filled: true,
                                  fillColor: const Color(0xFFF8F8FA),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black87, width: 1.5)),
                                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Veuillez sélectionner une date' : null,
                      ),

                      const SizedBox(height: 16),

                      const Text('TVA (%) *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTva,
                        decoration: InputDecoration(
                          labelText: 'Sélectionnez le taux',
                          prefixIcon: const Icon(Icons.percent),
                          filled: true,
                                  fillColor: const Color(0xFFF8F8FA),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black87, width: 1.5)),
                                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
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
                            minimumSize: const Size.fromHeight(54),
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

