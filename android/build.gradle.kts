import com.android.build.gradle.BaseExtension
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.2.2")
    }
}




val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    afterEvaluate {
        // Android 어플리케이션 또는 라이브러리 플러그인 확인
        if (pluginManager.hasPlugin("com.android.application") || 
            pluginManager.hasPlugin("com.android.library")) {
            
            extensions.configure<BaseExtension> { // BaseExtension으로 캐스팅
                compileSdkVersion(34) // compileSdkVersion 설정
                buildToolsVersion = "34.0.0" // buildToolsVersion 설정
            }
        }
    }
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

