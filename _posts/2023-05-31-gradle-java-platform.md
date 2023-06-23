---
author: Olivier
title: Gérer les dépendances dans des microservices Java avec Gradle Java Platform
categories: java spring springboot gradle
---

Si vous développez des microservices en Java avec Gradle, utilisez le plugin Gradle Java Platform pour gérer de manière transverse les dépendances (et leurs versions).

- [Introduction](#introduction)
- [Structure de base d'une Platform](#structure)
- [Publier la Java Platform](#publish)
- [Définir des dépendances obligatoires](#dependencies)
- [Définir des contraintes de versions](#constraints)
- [Utiliser la Java Platform](#consuming)
- [Liens](#links)


## Introduction <a class="anchor" name="introduction"></a>

En développant des microservices Java, vous allez probablement avoir un ensemble de dépendances communes à tous vos projets. Par exemple, si vous utilisez Spring Boot, tous vos projets inclueront probablement le [BOM Spring Boot](https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-dependencies). De même, vous utilisez peut-être mapstruct ou des bibliothèques similaires dans chaque projet.

Vous vous retrouverez avec un fichier build.gradle de ce type dupliqué dans chaque application : 
```java
plugins {
	id 'java'
	id 'org.springframework.boot' version '3.1.0'
  id 'io.spring.dependency-management' version '1.1.0'
}

group = 'fr.devmachine.gradle'
version = '0.0.1'
sourceCompatibility = '17'

repositories {
  mavenCentral()
}

dependencies {
  implementation 'org.springframework.boot:spring-boot-starter-web'
  implementation 'org.mapstruct:mapstruct:1.5.5.Final'
}
```

Plusieurs problèmes apparaissent déjà : 
* les versions sont dupliquées un peu partout, ce qui rend les mises à jour un peu compliquées
* les versions étant définies pour chaque projet, vous avez de grandes chances d'utiliser autant de versions différentes que de projets
* en complément du précédent point, si vous avez validé des versions d'une dépendance pour votre contexte, vous aimeriez n'utilisez que ces versions
* pour les dépendances que vous souhaitez inclure obligatoirement, vous avez beaucoup de risques que les développeurs en oublient lors de la création de nouveau projets (notamment des bibliothèques de monitoring et/ou tracing telles que micrometer).

Le plugin [Gradle Java Platform Plugin](https://docs.gradle.org/current/userguide/java_platform_plugin.html) va vous aider à résoudre ces problématiques. Il s'agit d'un plugin officiel fourni dans la distribution standard de gradle.

Il permet de déclarer les dépendances sous forme de : 
* ***constraint***: si une dépendance est ajoutée dans une application utilisant la ***Platform*** la version déclarée par la contrainte sera utilisée
* ***dependency***: dès que la ***Platform*** est consommée par une application, les dépendances déclarées dans le bloc `dependencies` seront ajoutées au graphe, que l'application l'ait déclarée explicitement ou non.

## Structure de base d'une Platform <a class="anchor" name="structure"></a>

La structure de base d'une ***Java Platform*** n'est autre qu'un projet avec simplement un fichier build.gradle. Il ne servira qu'à déclarer les dépendances et contraintes *presque* comme vous avez l'habitude de le faire.

Nous allons commencer par déclarer un module qui sera publiable, même si dans un premier temps il ne déclare aucune dépendance.
```java
plugins {
  id 'java-platform'
}

group = 'fr.devmachine.gradle'
version = '0.0.1'

javaPlatform {
  allowDependencies()
}

dependencies {

}

```

Deux notions apparaissent ici : 
* nous activons le plugin `java-platform` à la ligne 2
* nous autorisons la déclaration de dépendances à la ligne 10. Par défaut ce comportement est désactivé pour éviter d'ajouter des dépendances de manière involontaire. Sans cette option, seule la déclaration de contrainte est possible.

Ce module sera publié (généralement sur un dépôt maven) afin d'être consommé par les applications. Il contiendra un fichier ***.pom*** au format [Maven BOM](https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#bill-of-materials-bom-poms) et également un fichier ***.module*** au format [Gradle Metadata](https://github.com/gradle/gradle/blob/master/subprojects/docs/src/docs/design/gradle-module-metadata-latest-specification.md). Il est donc possible de l'utiliser dans les deux types de projets (Maven ou Gradle, cet article ne couvrant que le cas de Gradle).

## Publier la Java Platform <a class="anchor" name="publish"></a>

Pour publier le module, il faut ajouter la configuration de la tâche `publishing` comme ceci :
```java
publishing {
  publications {
    myPlatform(MavenPublication) {
      from components.javaPlatform
    }
  }
}
```

Il suffit ensuite d'exécuter la commande suivante (nous publions ici dans le dépôt maven local mais il est bien entendu possible de le publier, et recommandé, sur un dépôt distant) : 
```shell
./gradlew publishToMavenLocal
```

## Définir des dépendances obligatoires <a class="anchor" name="dependencies"></a>

Dans notre exemple, nous souhaitons que `commons-lang3` soit inclus dans tous nos projets, ainsi que `Spring Boot` dans une version précise.

Il suffit de déclarer ces dépendances dans la section `dependencies` de votre ***Platform***, comme ceci:

```java
plugins {
  id 'java-platform'
}

group = 'fr.devmachine.gradle'
version = '0.0.1'

javaPlatform {
  allowDependencies()
}

dependencies {
  api platform('org.springframework.boot:spring-boot-dependencies:3.1.0')
  api 'org.springframework.boot:spring-boot-starter-web'
  api 'org.apache.commons:commons-lang3:3.12.0'
}

```

Vous voyez ici que les trois déclarations différent légèrement :
* `commons-lang3` est déclaré avec simplement la configuration `api`, qui permet d'exposer une dépendance
* `spring-boot-dependencies` est déclaré avec la configuration `api` mais également avec `platform`, qui permet d'importer les dépendances elles-mêmes définies dans une `Platform` ou un `Maven BOM`. Nous reviendrons sur l'utilisation d'une `Platform` dans la section [Utiliser la Java Platform](#consuming)
* `spring-boot-starter-web` est quant à lui déclaré avec la configuration `api` mais sans version pour importer ce module en utilisant la version déclaré dans le BOM `spring-boot-dependencies`

## Définir des contraintes de versions <a class="anchor" name="constraints"></a>

Maintenant, imaginons que vous ayez une dépendance optionnelle, mais dont vous voulez exposer une version recommandée car vous l'avez validée en interne, par exemple Mapstruct.
Vous allez simplement pouvoir le faire en définissant cette version dans le bloc ***constraints***:
```java
plugins {
  id 'java-platform'
}

group = 'fr.devmachine.gradle'
version = '0.0.1'

javaPlatform {
  allowDependencies()
}

dependencies {
  api 'org.apache.commons:commons-lang3:3.12.0'

  constraints {
    api 'org.mapstruct:mapstruct:1.5.5.Final'
  }
}

```

## Utiliser la Java Platform <a class="anchor" name="consuming"></a>

Une fois publiée, il ne reste plus qu'à utiliser cette ***Platform***.
Dans votre projet applicatif, changez le `build.gradle` comme ceci: 
```
plugins {
  id 'java'
}

group = 'fr.devmachine.gradle'
version = '0.0.1'
sourceCompatibility = '17'

repositories {
  mavenCentral()
  mavenLocal()
}

dependencies {
  implementation platform('fr.devmachine.gradle:gradle-java-platform-sample:0.0.1')
}

```

Vous aurez remarqué que nous avons supprimé les dépendances explicites à `spring-boot` et `commons-lang3` car elles sont définies dans notre module `gradle-java-platform-sample`.

Pour vérifier le comportement, affichons le graphe de dépendances du projet :
```
$ ./gradlew dependencies --configuration compileClasspath

compileClasspath - Compile classpath for source set 'main'.
\--- fr.devmachine.gradle:gradle-java-platform-sample:0.0.1
     +--- org.springframework.boot:spring-boot-dependencies:3.1.0
     |    +--- org.apache.commons:commons-lang3:3.12.0 (c)
     |    +--- org.springframework.boot:spring-boot-starter-web:3.1.0 (c)
     |    +--- org.springframework.boot:spring-boot-starter:3.1.0 (c)
     |    +--- org.springframework.boot:spring-boot-starter-json:3.1.0 (c)
     |    +--- org.springframework.boot:spring-boot-starter-tomcat:3.1.0 (c)
     |    +--- org.springframework:spring-web:6.0.9 (c)
     |    +--- org.springframework:spring-webmvc:6.0.9 (c)
     |    +--- org.springframework.boot:spring-boot:3.1.0 (c)
     |    +--- org.springframework.boot:spring-boot-autoconfigure:3.1.0 (c)
     |    +--- org.springframework.boot:spring-boot-starter-logging:3.1.0 (c)
     |    +--- jakarta.annotation:jakarta.annotation-api:2.1.1 (c)
     |    +--- org.springframework:spring-core:6.0.9 (c)
     |    +--- org.yaml:snakeyaml:1.33 (c)
     |    +--- com.fasterxml.jackson.core:jackson-databind:2.15.0 (c)
     |    +--- com.fasterxml.jackson.datatype:jackson-datatype-jdk8:2.15.0 (c)
     |    +--- com.fasterxml.jackson.datatype:jackson-datatype-jsr310:2.15.0 (c)
     |    +--- com.fasterxml.jackson.module:jackson-module-parameter-names:2.15.0 (c)
     |    +--- org.apache.tomcat.embed:tomcat-embed-core:10.1.8 (c)
     |    +--- org.apache.tomcat.embed:tomcat-embed-el:10.1.8 (c)
     |    +--- org.apache.tomcat.embed:tomcat-embed-websocket:10.1.8 (c)
     |    +--- org.springframework:spring-beans:6.0.9 (c)
     |    +--- io.micrometer:micrometer-observation:1.11.0 (c)
     |    +--- org.springframework:spring-aop:6.0.9 (c)
     |    +--- org.springframework:spring-context:6.0.9 (c)
     |    +--- org.springframework:spring-expression:6.0.9 (c)
     |    +--- ch.qos.logback:logback-classic:1.4.7 (c)
     |    +--- org.apache.logging.log4j:log4j-to-slf4j:2.20.0 (c)
     |    +--- org.slf4j:jul-to-slf4j:2.0.7 (c)
     |    +--- org.springframework:spring-jcl:6.0.9 (c)
     |    +--- com.fasterxml.jackson.core:jackson-annotations:2.15.0 (c)
     |    +--- com.fasterxml.jackson.core:jackson-core:2.15.0 (c)
     |    +--- io.micrometer:micrometer-commons:1.11.0 (c)
     |    +--- ch.qos.logback:logback-core:1.4.7 (c)
     |    +--- org.slf4j:slf4j-api:2.0.7 (c)
     |    \--- org.apache.logging.log4j:log4j-api:2.20.0 (c)
     +--- org.springframework.boot:spring-boot-starter-web -> 3.1.0
     |    +--- org.springframework.boot:spring-boot-starter:3.1.0
     |    |    +--- org.springframework.boot:spring-boot:3.1.0
     |    |    |    +--- org.springframework:spring-core:6.0.9
     |    |    |    |    \--- org.springframework:spring-jcl:6.0.9
     |    |    |    \--- org.springframework:spring-context:6.0.9
     |    |    |         +--- org.springframework:spring-aop:6.0.9
     |    |    |         |    +--- org.springframework:spring-beans:6.0.9
     |    |    |         |    |    \--- org.springframework:spring-core:6.0.9 (*)
     |    |    |         |    \--- org.springframework:spring-core:6.0.9 (*)
     |    |    |         +--- org.springframework:spring-beans:6.0.9 (*)
     |    |    |         +--- org.springframework:spring-core:6.0.9 (*)
     |    |    |         \--- org.springframework:spring-expression:6.0.9
     |    |    |              \--- org.springframework:spring-core:6.0.9 (*)
     |    |    +--- org.springframework.boot:spring-boot-autoconfigure:3.1.0
     |    |    |    \--- org.springframework.boot:spring-boot:3.1.0 (*)
     |    |    +--- org.springframework.boot:spring-boot-starter-logging:3.1.0
     |    |    |    +--- ch.qos.logback:logback-classic:1.4.7
     |    |    |    |    +--- ch.qos.logback:logback-core:1.4.7
     |    |    |    |    \--- org.slf4j:slf4j-api:2.0.4 -> 2.0.7
     |    |    |    +--- org.apache.logging.log4j:log4j-to-slf4j:2.20.0
     |    |    |    |    +--- org.apache.logging.log4j:log4j-api:2.20.0
     |    |    |    |    \--- org.slf4j:slf4j-api:1.7.36 -> 2.0.7
     |    |    |    \--- org.slf4j:jul-to-slf4j:2.0.7
     |    |    |         \--- org.slf4j:slf4j-api:2.0.7
     |    |    +--- jakarta.annotation:jakarta.annotation-api:2.1.1
     |    |    +--- org.springframework:spring-core:6.0.9 (*)
     |    |    \--- org.yaml:snakeyaml:1.33
     |    +--- org.springframework.boot:spring-boot-starter-json:3.1.0
     |    |    +--- org.springframework.boot:spring-boot-starter:3.1.0 (*)
     |    |    +--- org.springframework:spring-web:6.0.9
     |    |    |    +--- org.springframework:spring-beans:6.0.9 (*)
     |    |    |    +--- org.springframework:spring-core:6.0.9 (*)
     |    |    |    \--- io.micrometer:micrometer-observation:1.10.7 -> 1.11.0
     |    |    |         \--- io.micrometer:micrometer-commons:1.11.0
     |    |    +--- com.fasterxml.jackson.core:jackson-databind:2.15.0
     |    |    |    +--- com.fasterxml.jackson.core:jackson-annotations:2.15.0
     |    |    |    \--- com.fasterxml.jackson.core:jackson-core:2.15.0
     |    |    +--- com.fasterxml.jackson.datatype:jackson-datatype-jdk8:2.15.0
     |    |    |    +--- com.fasterxml.jackson.core:jackson-core:2.15.0
     |    |    |    +--- com.fasterxml.jackson.core:jackson-databind:2.15.0 (*)
     |    |    |    \--- com.fasterxml.jackson:jackson-bom:2.15.0
     |    |    |         +--- com.fasterxml.jackson.core:jackson-annotations:2.15.0 (c)
     |    |    |         +--- com.fasterxml.jackson.core:jackson-core:2.15.0 (c)
     |    |    |         +--- com.fasterxml.jackson.core:jackson-databind:2.15.0 (c)
     |    |    |         +--- com.fasterxml.jackson.datatype:jackson-datatype-jdk8:2.15.0 (c)
     |    |    |         +--- com.fasterxml.jackson.datatype:jackson-datatype-jsr310:2.15.0 (c)
     |    |    |         \--- com.fasterxml.jackson.module:jackson-module-parameter-names:2.15.0 (c)
     |    |    +--- com.fasterxml.jackson.datatype:jackson-datatype-jsr310:2.15.0
     |    |    |    +--- com.fasterxml.jackson.core:jackson-annotations:2.15.0
     |    |    |    +--- com.fasterxml.jackson.core:jackson-core:2.15.0
     |    |    |    +--- com.fasterxml.jackson.core:jackson-databind:2.15.0 (*)
     |    |    |    \--- com.fasterxml.jackson:jackson-bom:2.15.0 (*)
     |    |    \--- com.fasterxml.jackson.module:jackson-module-parameter-names:2.15.0
     |    |         +--- com.fasterxml.jackson.core:jackson-core:2.15.0
     |    |         +--- com.fasterxml.jackson.core:jackson-databind:2.15.0 (*)
     |    |         \--- com.fasterxml.jackson:jackson-bom:2.15.0 (*)
     |    +--- org.springframework.boot:spring-boot-starter-tomcat:3.1.0
     |    |    +--- jakarta.annotation:jakarta.annotation-api:2.1.1
     |    |    +--- org.apache.tomcat.embed:tomcat-embed-core:10.1.8
     |    |    +--- org.apache.tomcat.embed:tomcat-embed-el:10.1.8
     |    |    \--- org.apache.tomcat.embed:tomcat-embed-websocket:10.1.8
     |    |         \--- org.apache.tomcat.embed:tomcat-embed-core:10.1.8
     |    +--- org.springframework:spring-web:6.0.9 (*)
     |    \--- org.springframework:spring-webmvc:6.0.9
     |         +--- org.springframework:spring-aop:6.0.9 (*)
     |         +--- org.springframework:spring-beans:6.0.9 (*)
     |         +--- org.springframework:spring-context:6.0.9 (*)
     |         +--- org.springframework:spring-core:6.0.9 (*)
     |         +--- org.springframework:spring-expression:6.0.9 (*)
     |         \--- org.springframework:spring-web:6.0.9 (*)
     \--- org.apache.commons:commons-lang3:3.12.0

```

Nous voyons bien ici que `org.springframework.boot:spring-boot-starter-web` est importé dans notre projet avec la version 3.1.0 comme déclaré dans notre ***Platform***, ainsi que les dépendances transitives.
De même `org.apache.commons:commons-lang3` est bien présent en version 3.12.0. Mais `org.mapstruct:mapstruct` n'apparait pas car il n'est pas explicitement déclaré dans notre application, et n'était qu'en contrainte dans la ***Platform***.

Ajoutons maintenant `org.mapstruct:mapstruct` dans notre application comme ceci: 
```java
plugins {
  id 'java'
}

group = 'fr.devmachine.gradle'
version = '0.0.1'
sourceCompatibility = '17'

repositories {
  mavenCentral()
  mavenLocal()
}

dependencies {
  implementation platform('fr.devmachine.gradle:gradle-java-platform-sample:0.0.1')
  implementation "org.mapstruct:mapstruct"
}

```

Et affichons de nouveau le graphe de dépendances: 
```
./gradlew dependencies --configuration compileClasspath


compileClasspath - Compile classpath for source set 'main'.
+--- fr.devmachine.gradle:gradle-java-platform-sample:0.0.1
|    +--- org.springframework.boot:spring-boot-dependencies:3.1.0
|    |    +--- org.apache.commons:commons-lang3:3.12.0 (c)
|    |    +--- org.springframework.boot:spring-boot-starter-web:3.1.0 (c)
|    |    +--- org.springframework.boot:spring-boot-starter:3.1.0 (c)
|    |    +--- org.springframework.boot:spring-boot-starter-json:3.1.0 (c)
|    |    +--- org.springframework.boot:spring-boot-starter-tomcat:3.1.0 (c)
|    |    +--- org.springframework:spring-web:6.0.9 (c)
|    |    +--- org.springframework:spring-webmvc:6.0.9 (c)
|    |    +--- org.springframework.boot:spring-boot:3.1.0 (c)
|    |    +--- org.springframework.boot:spring-boot-autoconfigure:3.1.0 (c)
|    |    +--- org.springframework.boot:spring-boot-starter-logging:3.1.0 (c)
|    |    +--- jakarta.annotation:jakarta.annotation-api:2.1.1 (c)
|    |    +--- org.springframework:spring-core:6.0.9 (c)
|    |    +--- org.yaml:snakeyaml:1.33 (c)
|    |    +--- com.fasterxml.jackson.core:jackson-databind:2.15.0 (c)
|    |    +--- com.fasterxml.jackson.datatype:jackson-datatype-jdk8:2.15.0 (c)
|    |    +--- com.fasterxml.jackson.datatype:jackson-datatype-jsr310:2.15.0 (c)
|    |    +--- com.fasterxml.jackson.module:jackson-module-parameter-names:2.15.0 (c)
|    |    +--- org.apache.tomcat.embed:tomcat-embed-core:10.1.8 (c)
|    |    +--- org.apache.tomcat.embed:tomcat-embed-el:10.1.8 (c)
|    |    +--- org.apache.tomcat.embed:tomcat-embed-websocket:10.1.8 (c)
|    |    +--- org.springframework:spring-beans:6.0.9 (c)
|    |    +--- io.micrometer:micrometer-observation:1.11.0 (c)
|    |    +--- org.springframework:spring-aop:6.0.9 (c)
|    |    +--- org.springframework:spring-context:6.0.9 (c)
|    |    +--- org.springframework:spring-expression:6.0.9 (c)
|    |    +--- ch.qos.logback:logback-classic:1.4.7 (c)
|    |    +--- org.apache.logging.log4j:log4j-to-slf4j:2.20.0 (c)
|    |    +--- org.slf4j:jul-to-slf4j:2.0.7 (c)
|    |    +--- org.springframework:spring-jcl:6.0.9 (c)
|    |    +--- com.fasterxml.jackson.core:jackson-annotations:2.15.0 (c)
|    |    +--- com.fasterxml.jackson.core:jackson-core:2.15.0 (c)
|    |    +--- io.micrometer:micrometer-commons:1.11.0 (c)
|    |    +--- ch.qos.logback:logback-core:1.4.7 (c)
|    |    +--- org.slf4j:slf4j-api:2.0.7 (c)
|    |    \--- org.apache.logging.log4j:log4j-api:2.20.0 (c)
|    +--- org.springframework.boot:spring-boot-starter-web -> 3.1.0
|    |    +--- org.springframework.boot:spring-boot-starter:3.1.0
|    |    |    +--- org.springframework.boot:spring-boot:3.1.0
|    |    |    |    +--- org.springframework:spring-core:6.0.9
|    |    |    |    |    \--- org.springframework:spring-jcl:6.0.9
|    |    |    |    \--- org.springframework:spring-context:6.0.9
|    |    |    |         +--- org.springframework:spring-aop:6.0.9
|    |    |    |         |    +--- org.springframework:spring-beans:6.0.9
|    |    |    |         |    |    \--- org.springframework:spring-core:6.0.9 (*)
|    |    |    |         |    \--- org.springframework:spring-core:6.0.9 (*)
|    |    |    |         +--- org.springframework:spring-beans:6.0.9 (*)
|    |    |    |         +--- org.springframework:spring-core:6.0.9 (*)
|    |    |    |         \--- org.springframework:spring-expression:6.0.9
|    |    |    |              \--- org.springframework:spring-core:6.0.9 (*)
|    |    |    +--- org.springframework.boot:spring-boot-autoconfigure:3.1.0
|    |    |    |    \--- org.springframework.boot:spring-boot:3.1.0 (*)
|    |    |    +--- org.springframework.boot:spring-boot-starter-logging:3.1.0
|    |    |    |    +--- ch.qos.logback:logback-classic:1.4.7
|    |    |    |    |    +--- ch.qos.logback:logback-core:1.4.7
|    |    |    |    |    \--- org.slf4j:slf4j-api:2.0.4 -> 2.0.7
|    |    |    |    +--- org.apache.logging.log4j:log4j-to-slf4j:2.20.0
|    |    |    |    |    +--- org.apache.logging.log4j:log4j-api:2.20.0
|    |    |    |    |    \--- org.slf4j:slf4j-api:1.7.36 -> 2.0.7
|    |    |    |    \--- org.slf4j:jul-to-slf4j:2.0.7
|    |    |    |         \--- org.slf4j:slf4j-api:2.0.7
|    |    |    +--- jakarta.annotation:jakarta.annotation-api:2.1.1
|    |    |    +--- org.springframework:spring-core:6.0.9 (*)
|    |    |    \--- org.yaml:snakeyaml:1.33
|    |    +--- org.springframework.boot:spring-boot-starter-json:3.1.0
|    |    |    +--- org.springframework.boot:spring-boot-starter:3.1.0 (*)
|    |    |    +--- org.springframework:spring-web:6.0.9
|    |    |    |    +--- org.springframework:spring-beans:6.0.9 (*)
|    |    |    |    +--- org.springframework:spring-core:6.0.9 (*)
|    |    |    |    \--- io.micrometer:micrometer-observation:1.10.7 -> 1.11.0
|    |    |    |         \--- io.micrometer:micrometer-commons:1.11.0
|    |    |    +--- com.fasterxml.jackson.core:jackson-databind:2.15.0
|    |    |    |    +--- com.fasterxml.jackson.core:jackson-annotations:2.15.0
|    |    |    |    \--- com.fasterxml.jackson.core:jackson-core:2.15.0
|    |    |    +--- com.fasterxml.jackson.datatype:jackson-datatype-jdk8:2.15.0
|    |    |    |    +--- com.fasterxml.jackson.core:jackson-core:2.15.0
|    |    |    |    +--- com.fasterxml.jackson.core:jackson-databind:2.15.0 (*)
|    |    |    |    \--- com.fasterxml.jackson:jackson-bom:2.15.0
|    |    |    |         +--- com.fasterxml.jackson.core:jackson-annotations:2.15.0 (c)
|    |    |    |         +--- com.fasterxml.jackson.core:jackson-core:2.15.0 (c)
|    |    |    |         +--- com.fasterxml.jackson.core:jackson-databind:2.15.0 (c)
|    |    |    |         +--- com.fasterxml.jackson.datatype:jackson-datatype-jdk8:2.15.0 (c)
|    |    |    |         +--- com.fasterxml.jackson.datatype:jackson-datatype-jsr310:2.15.0 (c)
|    |    |    |         \--- com.fasterxml.jackson.module:jackson-module-parameter-names:2.15.0 (c)
|    |    |    +--- com.fasterxml.jackson.datatype:jackson-datatype-jsr310:2.15.0
|    |    |    |    +--- com.fasterxml.jackson.core:jackson-annotations:2.15.0
|    |    |    |    +--- com.fasterxml.jackson.core:jackson-core:2.15.0
|    |    |    |    +--- com.fasterxml.jackson.core:jackson-databind:2.15.0 (*)
|    |    |    |    \--- com.fasterxml.jackson:jackson-bom:2.15.0 (*)
|    |    |    \--- com.fasterxml.jackson.module:jackson-module-parameter-names:2.15.0
|    |    |         +--- com.fasterxml.jackson.core:jackson-core:2.15.0
|    |    |         +--- com.fasterxml.jackson.core:jackson-databind:2.15.0 (*)
|    |    |         \--- com.fasterxml.jackson:jackson-bom:2.15.0 (*)
|    |    +--- org.springframework.boot:spring-boot-starter-tomcat:3.1.0
|    |    |    +--- jakarta.annotation:jakarta.annotation-api:2.1.1
|    |    |    +--- org.apache.tomcat.embed:tomcat-embed-core:10.1.8
|    |    |    +--- org.apache.tomcat.embed:tomcat-embed-el:10.1.8
|    |    |    \--- org.apache.tomcat.embed:tomcat-embed-websocket:10.1.8
|    |    |         \--- org.apache.tomcat.embed:tomcat-embed-core:10.1.8
|    |    +--- org.springframework:spring-web:6.0.9 (*)
|    |    \--- org.springframework:spring-webmvc:6.0.9
|    |         +--- org.springframework:spring-aop:6.0.9 (*)
|    |         +--- org.springframework:spring-beans:6.0.9 (*)
|    |         +--- org.springframework:spring-context:6.0.9 (*)
|    |         +--- org.springframework:spring-core:6.0.9 (*)
|    |         +--- org.springframework:spring-expression:6.0.9 (*)
|    |         \--- org.springframework:spring-web:6.0.9 (*)
|    +--- org.apache.commons:commons-lang3:3.12.0
|    \--- org.mapstruct:mapstruct:1.5.5.Final (c)
\--- org.mapstruct:mapstruct -> 1.5.5.Final

```

Dorénavant, `org.mapstruct:mapstruct` est lui aussi importé en version 1.5.5.Final même s'il n'a pas été nécessaire de définir cette version dans notre application.

## Liens <a class="anchor" name="links"></a>

* [Documentation Gradle Java Platform](https://docs.gradle.org/current/userguide/java_platform_plugin.html)
* [Documentation Gradle Java Platform](https://docs.gradle.org/current/userguide/java_platform_plugin.html)
* [Code source de la plateforme d'exemple](https://github.com/olivierboudet/gradle-java-platform-sample)
* [Code source de l'application d'exemple](https://github.com/olivierboudet/gradle-java-platform-consumer-sample)