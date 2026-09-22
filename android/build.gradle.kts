plugins {
    // Plugin Google Services — requis pour Firebase (google-services.json)
    id("com.google.gms.google-services") version "4.4.4" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// AGP 9 rend bloquante la verification du compileSdk des plugins (AGP 8 avertissait seulement).
// Certains plugins Flutter (media_store_plus...) compilent encore en android-33 alors que leurs
// dependances AndroidX exigent 34+. On aligne tous les sous-projets sur le compileSdk de l'app.
// NB : ce bloc doit rester AVANT evaluationDependsOn(":app"), sinon afterEvaluate arrive trop tard.
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            try {
                val current = ext.javaClass.getMethod("getCompileSdk").invoke(ext) as? Int
                if (current == null || current < 36) {
                    ext.javaClass.getMethod("setCompileSdk", Integer::class.java).invoke(ext, 36)
                    logger.lifecycle("compileSdk force a 36 pour ${project.name} (etait $current)")
                }
            } catch (e: NoSuchMethodException) {
                // extension sans compileSdk : on ignore
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
