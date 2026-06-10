import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';

/// Sauvegarde un PDF dans les Téléchargements du téléphone.
/// Retourne le chemin du fichier sauvegardé.
Future<String> savePdfToDownloads(Uint8List bytes, String fileName) async {
  // ── Android ──────────────────────────────────────────────────────────────
  if (Platform.isAndroid) {
    // Demander permission si Android ≤ 9 (API 28)
    if (await _needsStoragePermission()) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Permission de stockage refusée');
      }
    }

    // 1ère tentative : chemin direct vers Téléchargements
    // Fonctionne sur Android ≤ 10 avec requestLegacyExternalStorage="true"
    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (await downloadsDir.exists()) {
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      if (await file.exists()) {
        return file.path;
      }
    }

    // 2ème tentative : répertoire externe de l'app
    final extDir = await getExternalStorageDirectory();
    if (extDir != null) {
      final file = File('${extDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }

    // Dernier recours : répertoire temporaire
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ── iOS ───────────────────────────────────────────────────────────────────
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

/// Affiche un toast de succès après téléchargement.
void showDownloadSuccessSnackBar(
  BuildContext context,
  String fileName,
  String savedPath, {
  bool isIos = false,
}) {
  showToast(
    context,
    'Téléchargé avec succès',
    fileName,
    ToastificationType.success,
  );
  OpenFile.open(savedPath);
}

/// Affiche un toast d'erreur.
void showDownloadErrorSnackBar(BuildContext context, String message) {
  showToast(
    context,
    'Erreur de téléchargement',
    message.replaceAll('Exception: ', ''),
    ToastificationType.error,
  );
}

Future<bool> _needsStoragePermission() async {
  if (!Platform.isAndroid) return false;
  try {
    // Extraire le SDK version depuis operatingSystemVersion si possible
    final versionStr = Platform.operatingSystemVersion;
    final sdkMatch = RegExp(r'SDK (\d+)').firstMatch(versionStr);
    if (sdkMatch != null) {
      final sdk = int.parse(sdkMatch.group(1)!);
      return sdk <= 28;
    }
    return false; // Par défaut Android 10+ → pas besoin
  } catch (_) {
    return false;
  }
}
