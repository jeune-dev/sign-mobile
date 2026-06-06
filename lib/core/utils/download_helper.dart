import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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

/// Affiche un SnackBar de succès après téléchargement.
void showDownloadSuccessSnackBar(
  BuildContext context,
  String fileName,
  String savedPath, {
  bool isIos = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFF00C896),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 5),
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Téléchargé avec succès',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
                Text(
                  fileName,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: 'Ouvrir',
        textColor: Colors.white,
        onPressed: () => OpenFile.open(savedPath),
      ),
    ),
  );
}

/// Affiche un SnackBar d'erreur.
void showDownloadErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.red[400],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.replaceAll('Exception: ', ''),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
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
