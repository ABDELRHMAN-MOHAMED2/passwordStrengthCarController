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

subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
            if (namespace == null) {
                namespace = when (project.name) {
                    "flutter_bluetooth_serial" -> "io.github.edufolly.flutterbluetoothserial"
                    else -> "com.example.${project.name.replace("-", "_")}"
                }
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
subprojects {
    configurations.all {
        resolutionStrategy.eachDependency {
            if (
                project.name == "flutter_bluetooth_serial" &&
                requested.group == "androidx.core" &&
                requested.name in setOf("core", "core-ktx")
            ) {
                useVersion("1.6.0")
            }
        }
    }
}
