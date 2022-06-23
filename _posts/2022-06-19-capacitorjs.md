---
author: Marc
title: Application cross platform et marque blanche avec Capacitor
categories: capacitor js angular ci cd
---

Pour les besoins d'un de nos clients, nous devions réaliser une application en **marque blanche**, disponible sur **iOS**, **Android** et en version **Web**.
Il s'agisssait d'une refonte d'un projet historique découpé en 2, un projet web responsive, et un projet hybrid (Apache Cordova) quasi-identique au projet web.   
Pour cette refonte, nous avons choisi un concurrent du projet Apache Cordova, nommé CapacitorJS (ou plus sobrement **Capacitor**).

- [Capacitor en bref](#capacitor)
- [Automatisation](#automatisation)
- [Ce qu'il faut retenir](#bilan)
- [Ressources](#ressources)


## Capacitor en bref <a class="anchor" name="capacitor"></a>

Capacitor est une librairie permettant de transformer une application Web, et ce quelque soit le framework choisi (Angular, React, Vue, etc.), en une application native hybride. Le coeur de Capacitor réside dans une librairie embarquée dans une WebView permettant de faire le pont entre l'application Web et les APIs natives des différentes plateformes.

![Capacitor Native runtime](/assets/images/capacitor/capacitor.png)
*source: https://capacitorjs.com/blog/how-capacitor-works*

Cet outil, développé et maintenu par l'équipe d'Ionic Framework, est fourni avec une CLI. Côté installation, rien de plus simple :

```bash
npm install @capacitor/core
npm install @capacitor/cli --save-dev
npx cap init
```

L'initialisation va créer un fichier avec quelques configurations par défaut. Dans ce fichier, on va retrouver des propriétés d'assez haut niveau permettant de configurer les plateformes ciblées (commme par exemple l'id unique de l'application ou le nom de l'application). Ce fichier peut être statique (JSON) ou dynamique (TypeScript).

Une fois Capacitor ajouté à notre projet, il suffit de lui ajouter une "capacité", Android ou iOS dans notre cas. Il faudra au préalable compiler notre webapp pour qu'elle soit synchronisée. 

```bash
ng build # pour un projet Angular dans notre cas
npx cap add android
npx cap add ios
```

Ces dernières 2 commandes vont créer les workspaces natifs de chaque environnement : un workspace AndroidStudio pour Android, un workspace XCode pour iOS.

A partir de cette étape, Capacitor ne nous fournit plus d'outil pour builder ou déployer les applications natives. **Capacitor ne nous dispense pas d'avoir des connaissances de ces différents environnements.** Il faudra recourir à des modifications dans les fichiers `AndroidManifest.xml` ou encore `Info.plist` pour modifier le comportement des applications. Capacitor encourage à utiliser l'outillage dédié à chaque p 

La CLI nous permet néanmoins de lancer les applications en local (en ayant au préalable configurer les environnments de développement de chaque plateforme).

```bash
npx cap run android # Test de l'apk sur un device virtuel ou physique
npx cap run ios
```

Enfin, à chaque mise à jour de notre application, une commande permet de synchroniser les changements sans re-générer les workspaces.

```bash
npx cap sync # synchronisation des plateformes détectées
```

### Tout est plugin

Pour intéragir avec les APIs natives, il faut passer par des plugins.
L'équipe Capacitor maintient une liste de plugins officiels, couvrant les cas d'utilisation les plus courant, de la gestion de la **Status Bar** aux **Push Notifications** en passant par le **SplashScreen**.

Certains de ces plugins vont même pouvoir être configuré via le fichier de configuration (`capacitor.config.(json|ts)`). D'autres, par contre vont demander (via leur documentation), d'aller ajouter manuellement certaines permissions dans les fichiers de configuration `AndroidManifest.xml` ou `Info.plist`.

Voici un exemple d'utilisation du plugin **Local Notifications** qui donne accès, comme son nom l'indique, aux notifications locales afin de pouvoir en programmer. 

```bash
npm install @capacitor/local-notifications # installation du plugin
```

```typescript
import { LocalNotifications } from '@capacitor/local-notifications'

public transferNotification(schema: PushNotificationSchema): void {
    const notifTime = new Date().getTime() + 5000
    LocalNotifications.schedule({
      notifications: [
        {
          body: schema.body!,
          title: schema.title!,
          id: 0,
          schedule: {
            at: new Date(notifTime),
          },
        },
      ],
    })
      .then((result) => console.log(result))
      .catch((error) => console.log(error))
  }
```

Capacitor permet également de développer ses propres plugins et fournit pour cela un outillage dans chaque environnement pour faire **le pont** entre la plateforme retenue et les informations transitant en javascript.

La dépôt [capacitor-community](https://github.com/capacitor-community) référence un grand nombre de plugins non officiels et non maintenus par l'équipe Capacitor. 

Auto-proclamé successeur du projet Apache Cordova, Capacitor est de fait compatible avec de nombreux plugins Cordova.

## Marque blanche et automatisation <a class="anchor" name="automatisation"></a>

Jusqu'ici, nous avons vu que l'on peut très facilement gérer une application et synchroniser les workspaces natifs. Mais rappelez-vous, il nous faut une application marque blanche (plus de 5 dans notre cas), et de plus testables sur plusieurs environnement (dev, recette et prod par exemple). On dénombre alors 30 livrables ! (2 plateformes (Android/iOS) * 5 marques blanches * 3 environnements)

On comprends alors qu'il va être difficile de synchroniser tous ces workspaces, avec leur configurations et leur assets qui diffèrent bien souvent d'une marque à l'autre.

### Automatisation manuelle

La première étape assez naturelle a été de reproduire les étapes citées plus haut par des scripts bashs. Ce qui ressemblerait à l'ensemble de ces commandes ("inlinées"): 

```bash
rm -Rf .apps/workspaces/android # ce répertoire est configurable
ng build --configuration app-$app-$env  
npx cap add android

xmlstarlet ed -L \
  -s "manifest" -t elem -n "uses-permission" \
  -i "manifest/uses-permission[not(@android:name)]" -t attr -n "android:name" -v "android.permission.RECORD_AUDIO" \
  apps/workspaces/android/app/src/main/AndroidManifest.xml

xmlstarlet ed -L \
  -s "manifest" -t elem -n "uses-permission" \
  -i "manifest/uses-permission[not(@android:name)]" -t attr -n "android:name" -v "android.permission.WRITE_EXTERNAL_STORAGE" \
  apps/workspaces/android/app/src/main/AndroidManifest.xml
xmlstarlet ed -L \
  -s "manifest" -t elem -n "uses-permission" \
  -i "manifest/uses-permission[not(@android:name)]" -t attr -n "android:name" -v "android.permission.READ_EXTERNAL_STORAGE" \
  apps/workspaces/android/app/src/main/AndroidManifest.xml
xmlstarlet ed -L \
  -i "manifest/application" -t attr -n "android:requestLegacyExternalStorage" -v "true" \
  apps/workspaces/android/app/src/main/AndroidManifest.xml

npx cordova-res ... # outil de génération des assets

versionName=$(grep -o '"version": *"[^"]*' package.json | grep -o '[^"]*$')
versionCode=$(echo $versionName | tr --delete .)
sed -i 's/versionName [0-9a-zA-Z -_]*/versionName "'"$versionName"'"/' ./apps/workspaces/android/app/build.gradle
sed -i 's/versionCode [0-9a-zA-Z -_]*/versionCode '$versionCode'/' ./apps/workspaces/android/app/build.gradle
```

L'utilisation ici (limité pour l'exemple) montre à quel point cela peut être verbeux,peu lisible et dépendant d'autres outils,comme `xmlstarlet` ou `sed` ici, qui demandent d'autres compétences.

### Capacitor Configure

Capacitor, par l'intermédiaire de ses guides, propose un outil d'automatisation de la configuration : **Capacitor Configure**. Il se décompose en 2 modules, **@capacitor/project** et **@capacitor/configure**.

Le module **project** permet d'automatiser ces actions de manière programmatique. Il s'appuie sur d'autres librairies pour pouvoir configurer les workspace AndroidStudio et XCode.
Voici un exemple permettant de configurer les **Entitlements** pour chaque type de build iOS.

```typescript
import { CapacitorProject } from '@capacitor/project'
import { CapacitorConfig } from '@capacitor/cli'

const config: CapacitorConfig = {
  ios: {
    path: 'apps/workspaces/ios',
  }
}
const project = new CapacitorProject(config)
const addApsEntitlement = async () => {
  await project.load()
  const target = await project.ios!.getAppTargetName()
  console.log('Add Push Notification capability with aps-entitlements...')
  await project.ios?.addEntitlements(target, 'Debug', { 'aps-environment': 'development' })
  await project.ios?.addEntitlements(target, 'Release', { 'aps-environment': 'production' })
  await project.commit()
}
addApsEntitlement()
```


Le module **configure** quant à lui, s'appuie sur **@capacitor/project** pour permettre de faire de la configuration en mode déclaratif,  Cela se présente sous forme d'un ficher YAML.


```yaml
vars:
  APP_VERSION:
  APP_FULL_VERSION:

platforms:
  ios:
    targets:
      App:
        version: $APP_VERSION
        buildNumber: $APP_FULL_VERSION
        buildSettings:
          DEVELOPMENT_TEAM: XXXXXXXX
        plist:
          replace: true
          entries:
            - CFBundleDevelopmentRegion: fr_FR
            - UISupportedInterfaceOrientations: ['UIInterfaceOrientationPortrait']
            - UIRequiresFullScreen: true
            - UIViewControllerBasedStatusBarAppearance: true
            - NSCameraUsageDescription: Utilisation de la caméra
            - UIBackgroundModes: ['remote-notification']
        entitlements:
          - aps-environment: "production"
    android:
        manifest:
          - file: AndroidManifest.xml
            target: manifest
            inject: |
                <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
                <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
                <uses-feature android:name="android.hardware.location.gps" />
```

On voit bien dans cet exemple que l'injection des permissions est plus simple et compréhensible.

### Cas à la marge

Malheureusement, tout ne peux pas être fait. L'ajout de fichiers sources dans les workspaces n'est pas encore supporté dans ces outils.

 Car ce qu'on ne voit pas dans les exemples précédents, c'est que pour ajouter le support des **PushNotification**, il faut ajouter un fichier dans le workspace XCode (et Android, mais c'est plus simple). Pour cela, il ne suffit pas de déplacer un fichier... Non, non, non! Dans XCode chaque fichier est indexé dans le workspace (qui se fait automatiquement via l'ajout en drag & drop par exemple, difficile à automatiser). 
 
 Heureusement, il existe une libraire **nodejs** au nom bien choisi `xcode` !    
 Malheureusement, la documentation est très pauvre, et il faudra progresser à taton pour arriver à ses fins...

 ```javascript
 let xcode = require('xcode'),
  fs = require('fs'),
  projectPath = 'apps/workspaces/ios/App/App.xcodeproj/project.pbxproj',
  xcodeProject = xcode.project(projectPath);

xcodeProject.parse(function (err) {
  console.log('error ?', err);
  console.log('Creating resources group');
  const groupHash = xcodeProject.pbxCreateGroup('Resources');
  const targetName = 'App';
  console.log(`Retrieving target hash for ${targetName}`);
  const [targetHash] = Object.entries(xcodeProject.hash.project.objects['PBXNativeTarget']).find((entry) => {
    if (entry[1].name) {
      return entry[1].name === targetName;
    }
    return false;
  });
  console.log(`Adding files to target hash ${targetHash} and group hash ${groupHash}`);
  xcodeProject.addResourceFile('App/GoogleService-Info.plist', { target: targetHash }, groupHash);

  fs.writeFileSync(projectPath, xcodeProject.writeSync());
  console.log('GoogleService-Info plist added !');
});
 ```
*Exemple d'ajout de fichier dans le workspace XCode* 🤯


## En conclusion <a class="anchor" name="bilan"></a>

Capacitor nous apporte une facilité pour produire des applications hybrides, qui pourront être rendues disponibles via les "Stores" officiels, plus accessibles aux utilisateurs lambda. Et ce, avec une seule base de code (vraiment !) pour les cibles (web, android, iOS).

Cela ne nous dispense pas d'une connaissance des plateformes cibles. Il faudra faire attention au comportement des plugins selon les plateformes (firebase par défaut pour les push notifications Android, contre ajout d'un plugin pour iOS).

Enfin les outils d'automatisations sont encore jeunes et un peu capricieux, mais nous accordent de reproduire la génération sans devoir persister nos workspaces. 

## Sources et liens utiles <a class="anchor" name="ressources"></a>

Le projet **Capacitor Configure** est devenu très récemment [Trapeze](https://trapeze.dev) (Juin 2022) et est compatible avec d'autres technologies comme Flutter ou ReactNative. 

* [CapacitorJs](https://capacitorjs.com/)
* [Trapeze](https://trapeze.dev/)

