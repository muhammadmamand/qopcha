allprojects {
    repositories {
        google()
        mavenCentral()
        // Flutter engine artifacts (armeabi_v7a_release / arm64_v8a_release / …)
        maven(url = "https://storage.googleapis.com/download.flutter.io")
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
subprojects {
    project.evaluationDependsOn(":app")
}

// Avoid network-heavy lint tasks that fail under SSL interception / flaky DNS.
// Release annotation extraction must remain enabled because AGP consumes its output.
subprojects {
    tasks.configureEach {
        val n = name.lowercase()
        if (n.contains("lint")) {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
