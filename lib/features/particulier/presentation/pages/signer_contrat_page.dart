import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:signature/signature.dart';
import '../bloc/particulier_bloc.dart';
import '../bloc/particulier_event.dart';
import '../bloc/particulier_state.dart';
import '../../domain/entities/particulier_contrat.dart';

class SignerContratPage extends StatefulWidget {
  final ParticulierContrat contrat;
  const SignerContratPage({super.key, required this.contrat});

  @override
  State<SignerContratPage> createState() => _SignerContratPageState();
}

class _SignerContratPageState extends State<SignerContratPage> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _consentAccepted = false;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext ctx) async {
    if (!_consentAccepted) {
      showToast(ctx, 'Consentement requis', 'Veuillez accepter les conditions avant de signer.', ToastificationType.warning);
      return;
    }
    if (_signatureController.isEmpty) {
      showToast(ctx, 'Signature manquante', 'Veuillez tracer votre signature.', ToastificationType.warning);
      return;
    }

    final Uint8List? data = await _signatureController.toPngBytes();
    if (data == null) return;

    final base64Sig = 'data:image/png;base64,${base64Encode(data)}';

    if (!ctx.mounted) return;
    ctx.read<ParticulierBloc>().add(
      SignerContrat(
        type:      widget.contrat.type,
        contratId: widget.contrat.id,
        signature: base64Sig,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ParticulierBloc, ParticulierState>(
      listener: (ctx, state) {
        if (state is ContratSigne) {
          showToast(ctx, 'Contrat signé', 'Votre signature a été enregistrée avec succès', ToastificationType.success);
          Navigator.of(ctx).pop();
        }
        if (state is ParticulierError) {
          showToast(ctx, 'Erreur', state.message, ToastificationType.error);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Signer le contrat',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        body: BlocBuilder<ParticulierBloc, ParticulierState>(
          builder: (context, state) {
            final isLoading = state is ContratSignatureEnCours;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── En-tête contrat ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.contrat.typeLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(widget.contrat.numeroContrat,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      if (widget.contrat.generateurEntreprise != null ||
                          widget.contrat.generateurNom != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Émetteur : ${widget.contrat.generateurEntreprise ?? widget.contrat.generateurNom}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Texte de consentement ───────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                          const SizedBox(width: 8),
                          const Text('Déclaration de consentement',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'En apposant ma signature électronique, je certifie :\n'
                        '• Avoir lu et compris l\'intégralité du présent contrat.\n'
                        '• Accepter librement et sans contrainte ses termes et conditions.\n'
                        '• Que ma signature électronique a la même valeur juridique qu\'une signature manuscrite '
                        'conformément à la réglementation en vigueur au Sénégal.\n'
                        '• Être la personne désignée comme signataire dans ce contrat.',
                        style: TextStyle(fontSize: 12, height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Checkbox consentement ───────────────────────────
                GestureDetector(
                  onTap: () => setState(() => _consentAccepted = !_consentAccepted),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _consentAccepted ? Colors.black : Colors.white,
                          border: Border.all(color: _consentAccepted ? Colors.black : Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _consentAccepted
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'J\'accepte les conditions et je consens à signer électroniquement ce contrat.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Zone de signature ───────────────────────────────
                const Text('Votre signature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Signature(
                      controller: _signatureController,
                      height: 180,
                      backgroundColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                      label: const Text('Effacer', style: TextStyle(color: Colors.grey)),
                      onPressed: () => _signatureController.clear(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Bouton Soumettre ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isLoading ? null : () => _submit(context),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Confirmer et signer',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cette action est irréversible. Assurez-vous d\'avoir bien lu le contrat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
