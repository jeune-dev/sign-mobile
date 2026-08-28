import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/theme/app_dimensions.dart';
import 'package:sign_application/core/theme/app_typo.dart';
import 'package:sign_application/core/widgets/app_champ_texte.dart';
import 'package:sign_application/core/widgets/app_entete_formulaire.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
//
// Ces constantes ne définissent plus de valeurs propres : elles pointent vers
// le système partagé (`core/theme`). Les formulaires de contrats avaient
// dérivé — rayon 14 contre 12, fond #F9FAFB contre #F8F8FA, libellés 12 px
// contre 13 — et l'écart se voyait en passant d'un écran à l'autre.
//
// Elles restent exposées pour ne pas réécrire les pages qui les utilisent.
const double kCardRadius   = AppRayon.carte;
const double kFieldRadius  = AppRayon.champ;
const Color  kBgColor      = AppColor.kFond;
const Color  kCardColor    = AppColor.kSurface;
const Color  kLabelColor   = AppColor.kTexteMoyen;
const Color  kValueColor   = AppColor.kTexte;
const Color  kBorderColor  = AppColor.kBordure;
const Color  kSubtleColor  = AppColor.kChamp;

List<BoxShadow> get kCardShadow => [
  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
];

// ─── Step indicator ───────────────────────────────────────────────────────────

class CStepBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;
  final Color accentColor;

  const CStepBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            // Connecting line
            final stepIdx = (i - 1) ~/ 2;
            final done = currentStep > stepIdx + 1;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                decoration: BoxDecoration(
                  color: done ? accentColor : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final isActive = stepIdx == currentStep;
          final isDone   = stepIdx < currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? accentColor
                      : isDone
                          ? accentColor.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isActive || isDone
                        ? accentColor
                        : Colors.white.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : Text(
                          '${stepIdx + 1}',
                          style: TextStyle(
                            color: isActive || isDone
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[stepIdx],
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : isDone
                          ? accentColor.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.4),
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Black page header ─────────────────────────────────────────────────────────

class CFormHeader extends StatelessWidget {
  final String titre;
  final String stepTitle;
  final String stepSubtitle;
  final IconData icon;
  final Color accentColor;
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final VoidCallback onBack;

  const CFormHeader({
    super.key,
    required this.titre,
    required this.stepTitle,
    required this.stepSubtitle,
    required this.icon,
    required this.accentColor,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // Rendu délégué à la barre partagée : les écrans de contrats, de facture
    // et de fiche de paie affichaient trois en-têtes différents. La signature
    // de ce composant est conservée pour ne pas réécrire les pages.
    return AppEnteteFormulaire(
      titre: titre,
      sousTitre: stepSubtitle,
      icone: icon,
      accent: accentColor,
      onRetour: onBack,
      etapeCourante: currentStep,
      totalEtapes: totalSteps,
      libellesEtapes: stepLabels,
    );
  }
}

class CSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;
  final String? subtitle;

  const CSection({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.children,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with left accent bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: accentColor, width: 4)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(kCardRadius),
                topRight: Radius.circular(kCardRadius),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: kValueColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          style: const TextStyle(fontSize: 11, color: kLabelColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: kBorderColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Styled text field ────────────────────────────────────────────────────────

class CField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final int maxLines;
  final TextInputType keyboardType;
  final Color accentColor;
  final IconData? icon;
  final List<TextInputFormatter>? inputFormatters;

  const CField({
    super.key,
    required this.controller,
    required this.label,
    required this.accentColor,
    this.hint,
    this.required = true,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.icon,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CLabel(label: label, required: required, accentColor: accentColor),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          // Clavier numérique sans formateur explicite → chiffres uniquement.
          inputFormatters: inputFormatters ??
              (keyboardType == TextInputType.number
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null),
          style: const TextStyle(fontSize: 14, color: kValueColor, fontWeight: FontWeight.w500),
          decoration: _fieldDec(hint, icon, accentColor),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
              : null,
        ),
      ],
    );
  }
}

// ─── Champ durée : nombre (chiffres uniquement) + unité ─────────────────────────
//
// Écrit dans [controller] une chaîne combinée « 3 mois » pour rester compatible
// avec l'envoi existant (duree_mission, etc.). La saisie n'accepte que des chiffres,
// l'unité est choisie dans une liste fermée → impossible de saisir « hhsvs ».

const List<String> kUnitesDuree = ['jour(s)', 'semaine(s)', 'mois', 'année(s)'];

class CDurationField extends StatefulWidget {
  /// Libellé de l'unité « sans nombre » (durée indéterminée).
  static const String uniteIndeterminee = 'Indéterminée';

  final TextEditingController controller;
  final String label;
  final Color accentColor;
  final IconData? icon;
  final bool required;
  final List<String> unites;
  // Ajoute l'option « Indéterminée » (masque alors le champ nombre).
  final bool autoriserIndetermine;

  const CDurationField({
    super.key,
    required this.controller,
    required this.label,
    required this.accentColor,
    this.icon,
    this.required = true,
    this.unites = kUnitesDuree,
    this.autoriserIndetermine = false,
  });

  @override
  State<CDurationField> createState() => _CDurationFieldState();
}

class _CDurationFieldState extends State<CDurationField> {
  final TextEditingController _nbCtrl = TextEditingController();
  late String _unite;

  List<String> get _unites => widget.autoriserIndetermine
      ? [...widget.unites, CDurationField.uniteIndeterminee]
      : widget.unites;

  bool get _estIndetermine => _unite == CDurationField.uniteIndeterminee;

  @override
  void initState() {
    super.initState();
    _unite = _unites.first;
    // Pré-remplissage si le contrôleur contient déjà « 3 mois » ou « Indéterminée »
    final existant = widget.controller.text.trim();
    if (existant == CDurationField.uniteIndeterminee && widget.autoriserIndetermine) {
      _unite = CDurationField.uniteIndeterminee;
    } else {
      final parts = existant.split(RegExp(r'\s+'));
      if (parts.length >= 2 && int.tryParse(parts.first) != null) {
        _nbCtrl.text = parts.first;
        final u = parts.sublist(1).join(' ');
        if (_unites.contains(u)) _unite = u;
      }
    }
    _sync();
  }

  void _sync() {
    if (_estIndetermine) {
      widget.controller.text = CDurationField.uniteIndeterminee;
      return;
    }
    final nb = _nbCtrl.text.trim();
    widget.controller.text = nb.isEmpty ? '' : '$nb $_unite';
  }

  @override
  void dispose() {
    _nbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CLabel(label: widget.label, required: widget.required, accentColor: widget.accentColor),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _nbCtrl,
                enabled: !_estIndetermine,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _sync(),
                style: const TextStyle(fontSize: 14, color: kValueColor, fontWeight: FontWeight.w500),
                decoration: _fieldDec('Ex: 3', widget.icon, widget.accentColor),
                validator: (widget.required && !_estIndetermine)
                    ? (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                initialValue: _unite,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: kValueColor, fontWeight: FontWeight.w500),
                decoration: _fieldDec(null, Icons.schedule_outlined, widget.accentColor),
                items: _unites
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _unite = v);
                  _sync();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Date picker field ────────────────────────────────────────────────────────

class CDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final Color accentColor;
  final bool required;
  final VoidCallback onTap;

  const CDateField({
    super.key,
    required this.label,
    required this.accentColor,
    required this.onTap,
    this.value,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = value != null
        ? DateFormat('dd MMMM yyyy', 'fr_FR').format(value!)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CLabel(label: label, required: required, accentColor: accentColor),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: value != null ? accentColor.withValues(alpha: 0.06) : kSubtleColor,
              borderRadius: BorderRadius.circular(kFieldRadius),
              border: Border.all(
                color: value != null ? accentColor.withValues(alpha: 0.4) : kBorderColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 18,
                  color: value != null ? accentColor : kLabelColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    formatted ?? 'Sélectionner une date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                      color: value != null ? kValueColor : kLabelColor,
                    ),
                  ),
                ),
                if (value != null)
                  Icon(Icons.check_circle_rounded, size: 16, color: accentColor),
                if (value == null)
                  Icon(Icons.chevron_right_rounded, size: 18, color: kLabelColor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Dropdown field ───────────────────────────────────────────────────────────

class CDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final Color accentColor;
  final IconData? icon;
  final bool required;

  const CDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.accentColor,
    this.icon,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CLabel(label: label, required: required, accentColor: accentColor),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          decoration: _fieldDec(null, icon, accentColor),
          style: const TextStyle(fontSize: 14, color: kValueColor, fontWeight: FontWeight.w500),
          dropdownColor: Colors.white,
          icon: Icon(Icons.expand_more_rounded, color: accentColor, size: 20),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ─── Toggle row ───────────────────────────────────────────────────────────────

class CToggle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const CToggle({
    super.key,
    required this.title,
    required this.value,
    required this.accentColor,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: value ? accentColor.withValues(alpha: 0.06) : kSubtleColor,
        borderRadius: BorderRadius.circular(kFieldRadius),
        border: Border.all(
          color: value ? accentColor.withValues(alpha: 0.35) : kBorderColor,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: value ? accentColor : kValueColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(fontSize: 11, color: kLabelColor))
            : null,
        value: value,
        activeThumbColor: accentColor,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        dense: true,
      ),
    );
  }
}

// ─── Client selector ──────────────────────────────────────────────────────────

class CClientDisplay extends StatelessWidget {
  final Client client;
  final Color accentColor;
  final String role;
  final VoidCallback onClear;

  const CClientDisplay({
    super.key,
    required this.client,
    required this.accentColor,
    required this.role,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final initials = '${client.prenom.isNotEmpty ? client.prenom[0] : ''}${client.nom.isNotEmpty ? client.nom[0] : ''}'
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${client.prenom} ${client.nom}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                if (client.email != null && client.email!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    client.email!,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info banner (step 1 hero) ────────────────────────────────────────────────

class CInfoBanner extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const CInfoBanner({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: kValueColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: kLabelColor, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary row (recap step) ─────────────────────────────────────────────────

class CSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color accentColor;

  const CSummaryRow({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: accentColor),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12, color: kLabelColor, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: kValueColor, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom navigation bar ────────────────────────────────────────────────────

class CBottomBar extends StatelessWidget {
  final int step;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool isLoading;
  final String submitLabel;
  final Color accentColor;

  const CBottomBar({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.onBack,
    required this.onNext,
    required this.accentColor,
    this.isLoading = false,
    this.submitLabel = 'Créer le contrat',
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: kCardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          if (step > 0) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: kSubtleColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorderColor),
                ),
                // FittedBox : avec une police systeme agrandie, « Retour »
                // s elargit et vole la place du bouton principal au lieu de
                // s adapter.
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 18, color: kValueColor),
                      SizedBox(width: 6),
                      Text('Retour', maxLines: 1, style: TextStyle(fontWeight: FontWeight.w600, color: kValueColor, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: GestureDetector(
              onTap: isLoading ? null : onNext,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  color: isLast ? accentColor : Colors.black,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (isLast ? accentColor : Colors.black).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      // Le libelle est libre (« Créer le contrat de
                      // confidentialite » fait plus du double de « Suivant ») et
                      // la place restante depend du bouton Retour : sans
                      // FittedBox, le Row debordait de la barre. Reduire un peu
                      // le texte vaut mieux que le tronquer.
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isLast ? submitLabel : 'Suivant',
                                  maxLines: 1,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Spacing helper ───────────────────────────────────────────────────────────

const Widget kGap = SizedBox(height: 14);
const Widget kGapSm = SizedBox(height: 10);
const Widget kGapLg = SizedBox(height: 20);

// ─── Private helpers ──────────────────────────────────────────────────────────

class _CLabel extends StatelessWidget {
  final String label;
  final bool required;
  final Color accentColor;

  const _CLabel({required this.label, required this.required, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    // Même convention que le reste de l'application : plutôt qu'une étoile sur
    // les champs requis — qui finit par en couvrir l'écran — on signale les
    // rares champs facultatifs.
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTypo.jakarta(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColor.kTexte,
            ),
          ),
        ),
        if (!required) ...[
          const SizedBox(width: AppEspace.s),
          Text(
            'facultatif',
            style: AppTypo.jakarta(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColor.kTexteFaible,
            ),
          ),
        ],
      ],
    );
  }
}

/// Décoration des champs de contrat.
///
/// Délègue entièrement au composant partagé : un champ de contrat est
/// désormais identique à un champ d'inscription ou de profil. La couleur
/// d'accent du type de contrat reste sur les en-têtes et les icônes de
/// section, mais plus sur les bordures de saisie — c'est ce qui donnait
/// l'impression de sept applications différentes.
InputDecoration _fieldDec(String? hint, IconData? icon, Color accentColor) =>
    AppChampTexte.decoration(indication: hint, icone: icon);

// ─── Date picker helper ───────────────────────────────────────────────────────

Future<DateTime?> cPickDate(BuildContext context, {DateTime? initial, DateTime? firstDate}) async {
  return showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: firstDate ?? DateTime(2000),
    lastDate: DateTime(2100),
    locale: const Locale('fr', 'FR'),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(primary: Colors.black),
      ),
      child: child!,
    ),
  );
}

// ─── Signature pad ────────────────────────────────────────────────────────────

/// Ouvre le pad de signature dans une dialog.
/// Retourne le [File] PNG enregistré dans le répertoire temporaire, ou null si annulé.
Future<File?> openSignaturePad(BuildContext context) async {
  final controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  try {
    // On RÉCUPÈRE le fichier renvoyé par Navigator.pop(dialogContext, file).
    // Auparavant le résultat de showDialog était ignoré et la fonction
    // renvoyait toujours null → la signature n'était jamais enregistrée.
    return await showDialog<File?>(
      context: context,
      builder: (dialogContext) {
        // AlertDialog enveloppe son contenu dans un IntrinsicWidth, qui mesure
        // ses enfants sous des contraintes de largeur NON bornées. Le widget
        // Signature dimensionne son canevas via un ConstrainedBox dont la largeur
        // vaut `width ?? double.infinity` : avec double.infinity, sa largeur
        // intrinsèque est infinie → le pad s'effondre et reste invisible.
        // On fixe donc une largeur FINIE dérivée de l'écran.
        final double padWidth =
            (MediaQuery.of(dialogContext).size.width - 96).clamp(240.0, 420.0);
        return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Votre signature', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: padWidth,
              height: 180,
              decoration: BoxDecoration(
                color: AppColor.kChamp,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColor.kBordure),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Signature(
                  controller: controller,
                  width: padWidth,
                  height: 180,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Dessinez votre signature ci-dessus', style: TextStyle(fontSize: 11, color: AppColor.kTexteMoyen)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => controller.clear(),
            child: const Text('Effacer', style: TextStyle(color: AppColor.kTexteMoyen)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler', style: TextStyle(color: AppColor.kTexteMoyen)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.isEmpty) return;
              final data = await controller.toPngBytes();
              if (!dialogContext.mounted) return;
              if (data != null) {
                final tempDir = await getTemporaryDirectory();
                final file = File('${tempDir.path}/sig_contrat_${DateTime.now().millisecondsSinceEpoch}.png');
                await file.writeAsBytes(data);
                if (dialogContext.mounted) Navigator.pop(dialogContext, file);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Valider'),
          ),
        ],
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

/// Widget d'affichage du champ signature (preview + tap pour ouvrir le pad).
class CSignatureSection extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;
  final Color accentColor;

  const CSignatureSection({
    super.key,
    required this.image,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Votre signature',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kLabelColor),
            children: [TextSpan(text: '  *', style: TextStyle(color: accentColor, fontWeight: FontWeight.w800))],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColor.kChamp,
              border: Border.all(
                color: image != null ? accentColor : AppColor.kBordure,
                width: image != null ? 2 : 1,
              ),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(image!, fit: BoxFit.contain),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.draw_outlined, size: 28, color: accentColor),
                      const SizedBox(height: 6),
                      Text(
                        'Signez ici',
                        style: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const Text(
                        'Touchez pour ouvrir le pad de signature',
                        style: TextStyle(color: kLabelColor, fontSize: 11),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
