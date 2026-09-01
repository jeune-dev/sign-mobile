package com.signapp.sign_application

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    /**
     * VULN-H05 — Protection des ecrans affichant une piece d'identite.
     *
     * FLAG_SECURE bloque la capture d'ecran, l'enregistrement video ET la
     * vignette conservee par le gestionnaire de taches. Cette derniere est le
     * vrai risque : Android photographie l'ecran a chaque changement d'app, et
     * la vignette d'une CNI survit a la fermeture de l'application.
     *
     * Le drapeau n'est PAS pose globalement : l'utilisateur doit pouvoir
     * capturer ses propres factures et contrats. Il est donc active a la
     * demande, ecran par ecran, depuis Flutter (voir SecuriteEcran).
     */
    private val CANAL = "signs/securite_ecran"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL)
            .setMethodCallHandler { appel, reponse ->
                when (appel.method) {
                    "activer" -> {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        reponse.success(null)
                    }
                    "desactiver" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        reponse.success(null)
                    }
                    else -> reponse.notImplemented()
                }
            }
    }
}
