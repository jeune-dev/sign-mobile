import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import 'package:sign_application/features/client/presentation/bloc/client_bloc.dart';
import 'package:sign_application/features/client/presentation/bloc/client_event.dart';
import 'package:sign_application/features/client/presentation/bloc/client_state.dart';

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
                  onTap: () => setState(() => _selectedClient = null),
                  child: const Icon(Icons.close, color: Colors.white70, size: 18),
                ),
              ],
            ),
          )
        else ...[
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Rechercher un client...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            onChanged: (v) {
              if (v.length >= 2) {
                context.read<ClientBloc>().add(RechercherClientsEvent(v));
              }
            },
          ),
          BlocBuilder<ClientBloc, ClientState>(
            builder: (context, state) {
              if (state is ClientLoading && _searchCtrl.text.length >= 2) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(color: Colors.black),
                );
              }
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
        ],
      ],
    );
  }
}
