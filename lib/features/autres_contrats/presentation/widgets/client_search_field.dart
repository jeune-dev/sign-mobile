import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import 'package:sign_application/features/client/presentation/bloc/client_bloc.dart';
import 'package:sign_application/features/client/presentation/bloc/client_event.dart';
import 'package:sign_application/features/client/presentation/bloc/client_state.dart';
import 'package:sign_application/features/parcours/presentation/widgets/autre_partie_sheet.dart';
import 'package:sign_application/core/validation/identifiant_validator.dart';

class ClientSearchField extends StatefulWidget {
  final String label;
  final void Function(Client client) onClientSelected;

  const ClientSearchField({
    super.key,
    required this.label,
    required this.onClientSelected,
  });

  @override
  State<ClientSearchField> createState() => _ClientSearchFieldState();
}

class _ClientSearchFieldState extends State<ClientSearchField> {
  final TextEditingController _searchCtrl = TextEditingController();
  Client? _selectedClient;

  /// Vrai quand la saisie constitue un critère de recherche complet.
  /// C'est la condition d'affichage des résultats : tant qu'elle est fausse,
  /// aucune liste n'apparaît.
  bool _critereComplet = false;

  /// Aide affichée sous le champ, adaptée à ce que l'utilisateur est en train
  /// de taper.
  String? _aideSaisie = 'E-mail, numéro de téléphone, ou nom et prénom';

  /// Décide si la saisie est exploitable, et sous quelle forme l'envoyer.
  ///
  /// La recherche accepte les trois critères, mais aucun résultat n'est
  /// affiché tant que le critère n'est pas complet : chercher dès le premier
  /// caractère afficherait une partie du répertoire — des coordonnées de
  /// tiers — à qui tape une seule lettre.
  ({bool complet, String? terme, String? aide}) _analyser(String saisie) {
    final texte = saisie.trim();
    if (texte.isEmpty) {
      return (complet: false, terme: null, aide: 'E-mail, numéro de téléphone, ou nom et prénom');
    }

    // E-mail : reconnu dès la présence d'un @, complet quand la syntaxe l'est.
    if (texte.contains('@')) {
      final resultat = IdentifiantValidator.email(texte);
      return (
        complet: resultat.estAcceptable,
        terme: resultat.valeur ?? texte,
        aide: resultat.estAcceptable ? null : 'Saisissez l’adresse e-mail complète',
      );
    }

    // Téléphone : dès que la saisie ne contient que des chiffres et des
    // signes de numéro, on attend le numéro entier.
    if (RegExp(r'^[0-9+\s.\-()]+$').hasMatch(texte)) {
      final resultat = IdentifiantValidator.telephone(texte);
      return (
        complet: resultat.estAcceptable,
        terme: resultat.valeur ?? texte,
        aide: resultat.estAcceptable ? null : resultat.message,
      );
    }

    // Nom : on exige le nom ET le prénom, comme la recherche de l'autre
    // partie côté backend — un prénom seul ramènerait trop de monde.
    final mots = texte.split(RegExp(r'\s+')).where((m) => m.length >= 2).toList();
    if (mots.length < 2) {
      return (complet: false, terme: null, aide: 'Saisissez le nom ET le prénom');
    }
    return (complet: true, terme: texte, aide: null);
  }

  void _surSaisie(String saisie) {
    final analyse = _analyser(saisie);
    if (analyse.complet != _critereComplet || analyse.aide != _aideSaisie) {
      setState(() {
        _critereComplet = analyse.complet;
        _aideSaisie = analyse.aide;
      });
    }
    if (analyse.complet && analyse.terme != null) {
      context.read<ClientBloc>().add(RechercherClientsEvent(analyse.terme!));
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        if (_selectedClient != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_selectedClient!.prenom} ${_selectedClient!.nom}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedClient = null;
                    _critereComplet = false;
                    _aideSaisie = 'E-mail, numéro de téléphone, ou nom et prénom';
                    _searchCtrl.clear();
                  }),
                  child: const Icon(Icons.close, color: Colors.white70, size: 18),
                ),
              ],
            ),
          )
        else ...[
          // Recherche par e-mail, numéro de téléphone, ou nom et prénom.
          // Les résultats n'apparaissent qu'une fois le critère complet —
          // voir _analyser().
          TextField(
            controller: _searchCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'E-mail, téléphone, ou nom et prénom',
              helperText: _aideSaisie,
              helperStyle: const TextStyle(fontSize: 11.5),
              helperMaxLines: 2,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            onChanged: _surSaisie,
          ),
          BlocBuilder<ClientBloc, ClientState>(
            builder: (context, state) {
              if (state is ClientLoading && _critereComplet) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(color: Colors.black),
                );
              }
              // Tant que le critère est incomplet, aucun résultat n'est
              // affiché — même si le bloc en porte encore d'une saisie
              // précédente.
              if (!_critereComplet) return const SizedBox.shrink();
              if (state is ClientsRechercheLoaded && state.clients.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4)],
                  ),
                  child: Column(
                    children: state.clients.take(5).map((client) {
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black,
                          child: Text(
                            client.prenom.isNotEmpty ? client.prenom[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        title: Text('${client.prenom} ${client.nom}', style: const TextStyle(fontSize: 13)),
                        subtitle: client.email != null ? Text(client.email!, style: const TextStyle(fontSize: 11)) : null,
                        onTap: () {
                          setState(() => _selectedClient = client);
                          _searchCtrl.clear();
                          widget.onClientSelected(client);
                        },
                      );
                    }).toList(),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // § 8 : la personne n'est pas dans mes clients. On la cherche alors
          // dans tout SIGNS (préremplissage automatique si elle a un compte),
          // ou on l'invite à en créer un.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _ouvrirRechercheGlobale,
              icon: const Icon(Icons.person_search_outlined, size: 18),
              label: const Text(
                'Cette personne n’est pas dans ma liste',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Ouvre la recherche globale SIGNS (§ 8). Si une personne est retenue,
  /// elle est traitée exactement comme un client sélectionné.
  Future<void> _ouvrirRechercheGlobale() async {
    final partie = await AutrePartieSheet.afficher(context);
    if (partie == null || !mounted) return;
    setState(() => _selectedClient = partie);
    _searchCtrl.clear();
    widget.onClientSelected(partie);
  }
}
