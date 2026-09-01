import 'package:flutter/material.dart';
import 'package:sign_application/core/utils/marge_systeme.dart';

import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/theme/app_dimensions.dart';
import 'package:sign_application/core/theme/app_typo.dart';
import 'package:sign_application/core/widgets/app_entete_formulaire.dart';
import 'package:sign_application/injection_container.dart';

import '../data/notification_signs.dart';
import '../data/notifications_remote_datasource.dart';

/// notifications_page.dart — Le détail de ce qui est arrivé.
///
/// Ouverte depuis la cloche. Les notifications non lues sont mises en avant
/// par une pastille et un fond légèrement teinté ; ouvrir l'une d'elles la
/// marque lue et déplie son message complet.
///
/// Le dépliage sur place plutôt qu'un troisième écran : un message de
/// notification tient en deux ou trois lignes, ouvrir une page entière pour
/// l'afficher serait disproportionné.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationSigns> _notifications = const [];
  int _nonLues = 0;
  bool _chargement = true;

  /// Identifiants des notifications dépliées.
  final Set<String> _depliees = {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final resultat = await sl<NotificationsRemoteDataSource>().lister();
    if (!mounted) return;
    setState(() {
      _notifications = resultat.notifications;
      _nonLues = resultat.nonLues;
      _chargement = false;
    });
  }

  Future<void> _ouvrir(NotificationSigns notification) async {
    setState(() {
      if (!_depliees.remove(notification.id)) _depliees.add(notification.id);
    });

    if (!notification.nonLue) return;

    final restantes =
        await sl<NotificationsRemoteDataSource>().marquerLue(notification.id);
    if (!mounted) return;

    setState(() {
      _notifications = _notifications
          .map((n) => n.id == notification.id
              ? NotificationSigns(
                  id: n.id,
                  type: n.type,
                  titre: n.titre,
                  message: n.message,
                  cibleType: n.cibleType,
                  cibleId: n.cibleId,
                  luLe: DateTime.now(),
                  creeLe: n.creeLe,
                )
              : n)
          .toList();
      _nonLues = restantes ?? (_nonLues > 0 ? _nonLues - 1 : 0);
    });
  }

  Future<void> _toutMarquerLu() async {
    final ok = await sl<NotificationsRemoteDataSource>().toutMarquerLu();
    if (!mounted || !ok) return;
    await _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kFond,
      appBar: AppEnteteFormulaire.barre(
        titre: 'Notifications',
        sousTitre: _nonLues == 0
            ? 'Tout est à jour'
            : '$_nonLues non lue${_nonLues > 1 ? 's' : ''}',
        icone: Icons.notifications_none_rounded,
        onRetour: () => Navigator.of(context).pop(_nonLues),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              child: _notifications.isEmpty ? _vide() : _liste(),
            ),
    );
  }

  Widget _vide() {
    // En liste défilante malgré l'absence de contenu : sans cela, le geste de
    // rafraîchissement ne fonctionnerait pas sur un écran vide.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        Icon(Icons.notifications_off_outlined,
            size: 54, color: AppColor.kTexteFaible),
        const SizedBox(height: AppEspace.l),
        Center(
          child: Text(
            'Aucune notification',
            style: AppTypo.jakarta(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColor.kTexteFort,
            ),
          ),
        ),
        const SizedBox(height: AppEspace.s),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppEspace.xxl),
          child: Text(
            'Les documents reçus et les décisions concernant votre compte '
            'apparaîtront ici.',
            textAlign: TextAlign.center,
            style: AppTypo.jakarta(
              fontSize: 13.5,
              color: AppColor.kTexteMoyen,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _liste() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: avecMargeBasse(
          context,
          const EdgeInsets.fromLTRB(
              AppEspace.l, AppEspace.l, AppEspace.l, AppEspace.xxl)),
      itemCount: _notifications.length + (_nonLues > 0 ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppEspace.m),
      itemBuilder: (context, index) {
        if (_nonLues > 0 && index == 0) return _boutonToutLu();
        final notification = _notifications[_nonLues > 0 ? index - 1 : index];
        return _carte(notification);
      },
    );
  }

  Widget _boutonToutLu() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _toutMarquerLu,
        icon: const Icon(Icons.done_all_rounded, size: 18),
        label: Text(
          'Tout marquer comme lu',
          style: AppTypo.jakarta(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(foregroundColor: AppColor.kPrimary),
      ),
    );
  }

  Widget _carte(NotificationSigns notification) {
    final depliee = _depliees.contains(notification.id);
    final nonLue = notification.nonLue;

    return Material(
      color: nonLue ? AppColor.fondEtat(AppColor.kPrimary) : Colors.white,
      borderRadius: BorderRadius.circular(AppRayon.carte),
      child: InkWell(
        onTap: () => _ouvrir(notification),
        borderRadius: BorderRadius.circular(AppRayon.carte),
        child: Container(
          padding: const EdgeInsets.all(AppEspace.l),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRayon.carte),
            border: Border.all(
              color: nonLue ? AppColor.kPrimary.withValues(alpha: 0.28) : AppColor.kBordure,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: nonLue
                      ? AppColor.kPrimary.withValues(alpha: 0.14)
                      : AppColor.kNeutreClair,
                  borderRadius: BorderRadius.circular(AppRayon.champ),
                ),
                child: Icon(
                  notification.icone,
                  size: 20,
                  color: nonLue ? AppColor.kPrimary : AppColor.kTexteMoyen,
                ),
              ),
              const SizedBox(width: AppEspace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.titre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypo.jakarta(
                              fontSize: 14.5,
                              fontWeight: nonLue ? FontWeight.w800 : FontWeight.w600,
                              color: AppColor.kTexteFort,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (nonLue) ...[
                          const SizedBox(width: AppEspace.s),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColor.kPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.message,
                      maxLines: depliee ? null : 2,
                      overflow: depliee ? null : TextOverflow.ellipsis,
                      style: AppTypo.jakarta(
                        fontSize: 13,
                        color: AppColor.kTexteMoyen,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppEspace.s),
                    Text(
                      notification.quand,
                      style: AppTypo.jakarta(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColor.kTexteFaible,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
