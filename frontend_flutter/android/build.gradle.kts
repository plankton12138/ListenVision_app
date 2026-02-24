import com.android.build.api.dsl.LibraryExtension
import org.gradle.api.tasks.compile.JavaCompile
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    if (project.name == "on_audio_query_android") {
        val configureNamespace = {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    val setNamespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespaceMethod.invoke(android, "com.lucasjosino.on_audio_query")
                    println("Successfully set namespace for on_audio_query_android")
                } catch (e: Exception) {
                    println("Failed to set namespace for on_audio_query_android: ${e.message}")
                }
            }
        }

        val configureJvmTargets = {
            project.plugins.withId("com.android.library") {
                project.extensions.configure<LibraryExtension>("android") {
                    compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_17
                        targetCompatibility = JavaVersion.VERSION_17
                    }
                }
            }

            project.tasks.withType(JavaCompile::class.java).configureEach {
                sourceCompatibility = JavaVersion.VERSION_17.toString()
                targetCompatibility = JavaVersion.VERSION_17.toString()
            }

            project.tasks.withType(KotlinCompile::class.java).configureEach {
                kotlinOptions.jvmTarget = JavaVersion.VERSION_17.toString()
            }
        }

        if (project.state.executed) {
            configureNamespace()
            configureJvmTargets()
        } else {
            project.afterEvaluate {
                configureNamespace()
                configureJvmTargets()
            }
        }
    }
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
