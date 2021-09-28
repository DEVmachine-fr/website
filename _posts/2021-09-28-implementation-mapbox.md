---
author: Gwenolé
title: Implémentation de Mapbox GL js dans un projet angular
categories: Mapbox Angular
---


Nous vous partageons ici un tutoriel pour découvrir comment implémenter Mapbox GL js dans un projet angular

- [Introduction](#introduction)
- [Mapbox GL js, kézako ?](#kesaco)
- [Initialisation du projet](#initProject)
- [Intégration de Mapbox GL js](#integration)
    - [Mise en place du fond de carte](#initmap)
    - [Ajout d'un layer](#addlayer)
    - [Ajout évènement au clic](#clickevent)
- [Conclusion](#conclusion)

## Introduction <a class="anchor" name="introduction"></a>

Nous verrons tout d'abord comment créer le projet en Angular avec les librairies dont nous aurons besoin. Nous n'aurons pas pour ce tutoriel à créer de nouveau composant.

Nous allons ensuite voir comment implémenter une carte Mapbox avec un fond de carte, et nous allons ensuite ajouter une couche de données - aussi appelé layer - que nous allons exploiter pour faire ressortir certaines données sur notre carte.

Nous allons également ajouter une intéraction avec nos layer pour récupérer les informations qui nous intéresse dans le jeu de données associé.

## Mapbox GL js, kézako ? <a class="anchor" name="kesaco"></a>

Mapbox GL js est une librairie javascript développée par la société Mapbox. Cette librairie permet la visualisation de données cartographiques 2D ou 3D sur votre site ou votre application web.

Mapbox GL js s'appuie pour l'affichage 2D sur leafleet et sur three.js pour la 3D.

## Initialisation du projet <a class="anchor" name="initProject"></a>

Dans notre exemple, nous utiliserons node 14 et Mapbox GL js 7. Pour vérifier la version de node utilisée et les versions installé via nvm (Node Version Manager), on lance la commande :
{% include code-header.html %}
```
nvm list
```

Si la version de node souhaitée n'apparait pas, nous pouvons l'installer avec nvm :
{% include code-header.html %}
```
nvm install 14
```

Si la version souhaitée n'est pas celle utilisée, nous pouvons choisir une autre installée :
{% include code-header.html %}
```
nvm use 14
```

Nous allons ensuite installer angular CLI si ce n'est pas déjà fait :
{% include code-header.html %}
```
npm install -g @angular/cli
```

ensuite on génère notre projet angular :
{% include code-header.html %}
```
ng new angular-mapbox
```

Nous installons ensuite les librairies dont nous aurons besoin, mapbox-gl, @types/mapbox-gl et ngx-mapbox-gl ( ce dernier permet de faciliter l'intégration de Mapbox en tant que composant angular) :
{% include code-header.html %}
```
npm install mapbox-gl --save
npm install ngx-mapbox-gl --save
npm install @types/mapbox-gl --save
```

## Intégration de Mapbox GL js <a class="anchor" name="integration"></a>

### Mise en place du fond de carte <a class="anchor" name="initmap"></a>

Nous allons maintenant modifier le composant app pour afficher une carte Mapbox

Tout d'abord, Mapbox nécessite une clé d'utilisation si vous souhaitez aller plus loin et utiliser leurs API ou SDK. Vous pouvez créer un compte pour avoir votre propre clé.

Nous n'utiliserons dans notre cas les API Mapbox, nous pouvons donc nous contenter dans *app.modules.ts* d'importer le module *NgxMapboxGLModule* comme ceci : 
{% include code-header.html %}
```javascript
...
import { NgxMapboxGLModule } from 'ngx-mapbox-gl';
...
  imports: [
    ...
    NgxMapboxGLModule
  ],
```

Si vous souhaitez prendre en compte une clé Mapbox, il vous faudra modifier *app.module.ts* comme suit avec vos clés :
{% include code-header.html %}
```javascript
...
import { NgxMapboxGLModule } from 'ngx-mapbox-gl';
...
  imports: [
    ...
    NgxMapboxGLModule.withConfig({
      accessToken: 'TOKEN', // Optional, can also be set per map (accessToken input of mgl-map)
      geocoderAccessToken: 'TOKEN' // Optional, specify if different from the map access token, can also be set per mgl-geocoder (accessToken input of mgl-geocoder)
    })
  ],
```

On ajoute ensuite la variable style dans *app.component.ts* :
{% include code-header.html %}
```javascript
  style = {
    sources: {
      world: {
        type: "geojson",
        data: "https://raw.githubusercontent.com/johan/world.geo.json/master/countries.geo.json"
      }
    },
    version: 8,
    layers: [
      {
        "id": "countries",
        "type": "fill",
        "source": "world",
        "layout": {},
        "paint": {
          'fill-color': 'rgba(0, 0, 0, 0.4)',
          'fill-outline-color': 'rgba(50, 0, 0, 1)'
        }
      }
    ]
  };
```

Voyons plus en détail ce que nous avons renseigné. le composant Mapbox a donc une variable style qui contient plusieurs informations :
- *sources* dans laquelle chaque propriété est une source de données dans laquelle on retrouve les propriétés type pour le type de données et data pour le chemin utilisé pour récupérer ces données
- *version* qui sera la version de Mapbox que l'on veut utiliser
- *layers* contenant des couches de données à afficher. on y remplira ici un id pour l'identifier, le type de layer que l'on a, la source de donnée que l'on souhaite utiliser (déclarée dans *sources*), les styles à appliquer (la propriété paint et layout)

Nous allons ajouter quelques styles dans *app.component.scss* pour que la carte prenne l'ensemble de la page : 
{% include code-header.html %}
```css
mgl-map {
    height: 100vh;
    width: 100vw;
}
```

Nous allons également ajouter les styles fournies avec la librairie *ngx-mapbox-gl* pour avoir un affichage propre (vous pouvez surcharger les styles ensuite si vous le souhaitez).
Pour cela, dans *angular.json* nous allons modifier la propriété *styles* comme ceci :
{% include code-header.html %}
```json
            "styles": [
              "src/styles.scss",
              "./node_modules/mapbox-gl/dist/mapbox-gl.css",
              "./node_modules/@mapbox/mapbox-gl-geocoder/lib/mapbox-gl-geocoder.css"
            ],
```

Nous allons ensuite modifier le html de *app.component.html* pour intégrer la carte Mapbox :
{% include code-header.html %}
```html
<mgl-map
    [style]="style"
    [zoom]="[5]"
    [center]="[-1.6833, 48.1033]"
  >
</mgl-map>
```

On a en paramètre du composant le style définie dans *app.component.ts* précédemment, le niveau de zoom souhaité et les coordonnées de l'endroit sur lequel nous voulons centrer la carte.

On ajoute ensuite la variable *global* à la fin de *polyfills.ts* pour le bon fonctionnement de notre application ( vous trouverez plus d'explication à ce sujet [ici](https://github.com/angular/angular-cli/issues/9827#issuecomment-386154063)) :
{% include code-header.html %}
```javascript
(window as any).global = window;
```

Si vous lancez maintenant l'application avec :
{% include code-header.html %}
```
ng new angular-mapbox
```

vous devriez avoir ceci comme résultat : 

![Mise en place du fond de carte Mapbox](/assets/images/mapbox/mapbox-1.png)

### Ajout d'un layer <a class="anchor" name="addlayer"></a>

Nous allons maintenant ajouter un autre jeu de données geojson de polygones à afficher sur cette carte.
Pour cela nous allons dans notre exemple récupérer les limites communales de rennes métropole en polygones (lien [ici](https://data.rennesmetropole.fr/explore/dataset/limites-communales-referentielles-de-rennes-metropole-polygones/table/?disjunctive.nom&location=10,48.08726,-1.73378&basemap=0a029a&dataChart=eyJxdWVyaWVzIjpbeyJjb25maWciOnsiZGF0YXNldCI6ImxpbWl0ZXMtY29tbXVuYWxlcy1yZWZlcmVudGllbGxlcy1kZS1yZW5uZXMtbWV0cm9wb2xlLXBvbHlnb25lcyIsIm9wdGlvbnMiOnsiZGlzanVuY3RpdmUubm9tIjp0cnVlfX0sImNoYXJ0cyI6W3siYWxpZ25Nb250aCI6dHJ1ZSwidHlwZSI6ImNvbHVtbiIsImZ1bmMiOiJBVkciLCJ5QXhpcyI6Im9iamVjdGlkIiwic2NpZW50aWZpY0Rpc3BsYXkiOnRydWUsImNvbG9yIjoiIzY2YzJhNSJ9XSwieEF4aXMiOiJub20iLCJtYXhwb2ludHMiOjUwLCJzb3J0IjoiIn1dLCJ0aW1lc2NhbGUiOiIiLCJkaXNwbGF5TGVnZW5kIjp0cnVlLCJhbGlnbk1vbnRoIjp0cnVlfQ%3D%3D)).

Téléchargez le jeu de données au format json (vous pouvez le télécharger sous d'autre format, mais il faudra alors configurer Angular pour la lecture de ce type d'extension).
Nous le nommerons dans notre cas *communes-rennes.json*.

Nous allons maintenant modifier ce json dans l'outil de votre choix pour y ajouter deux propriétés pour chaque commune :
- *color* qui contiendra un code couleur (exemple : "#03FF98")
- *nbHabitant* qui contiendra le nombre d'habitant de la commune (ici on mettra des chiffres aléatoires pour ne pas s'embêter)

On va ajouter une propriété *cursorStyle* dans *app.component.ts* pour changer le style du curseur lorsque l'on passe sur les communes, mais également un objet source pour notre json :
{% include code-header.html %}
```javascript
  cursorStyle: string;
  communesRennes = {
    type: 'geojson',
    data: "../assets/communes-rennes.json"
  };
```

On ajoute cette propriété dans *app.component.html* et l'on changera également le niveau de zoom à 10 :
{% include code-header.html %}
```html
<mgl-map
    [style]="style"
    [zoom]="[10]"
    [center]="[-1.6833, 48.1033]"
    [cursorStyle]="cursorStyle"
  >
</mgl-map>
```

Toujours dans *app.component.html*, on ajoute ensuite notre layer :
{% include code-header.html %}
```html
<mgl-map
    [style]="style"
    [zoom]="[5]"
    [center]="[-1.6833, 48.1033]"
    [cursorStyle]="cursorStyle"
  >
  <mgl-layer
        id="communes-rennes"
        type="fill-extrusion"
        [source]="communesRennes"
        [paint]="{
          'fill-extrusion-color': ['get', 'color'],
          'fill-extrusion-height': ['/', ['to-number', ['get', 'nbHabitant']], 100],
          'fill-extrusion-base': 0,
          'fill-extrusion-opacity': 0.5
        }"
        (mouseEnter)="cursorStyle = 'pointer'"
        (mouseLeave)="cursorStyle = ''"
      ></mgl-layer>
</mgl-map>
```

dans mgl-layer on définit :
- *id* l'id unique du layer.
- *type* le type de layer que l'on souhaite utiliser. le type *fill-extrusion* nous permettra d'extruder, c'est à dire donner une hauteur à nos polygones pour avoir visualisation 3D de ceux-ci.
- *source* la source que l'on veut utiliser pour ce layer. Nous utiliserons donc *communesRennes* créée précédent pour utiliser notre json.
- *paint* les styles à appliquer à notre jeux de données. Ici on va :
  - faire en sorte que l'extrusion prenne la couleur de la propriété *color* de notre json (*fill-extrusion-color*)
  - faire que la hauteur de l'extrusion (*fill-extrusion-height*) dépendent du nombre d'habitant si elle existe (propriété *nbHabitant*)
  - faire que l'extrusion commence à une hauteur de 0 (*fill-extrusion-base*)
  - régler l'opacité des modèles générés (*fill-extrusion-opacity*)

On associe également les évènements *mouseEnter* et *mouseLeave* à la modification de la valeur de *cursorStyle*.

Vous devriez maintenant avoir un résultat semblable à ceci :

![Ajout d'un layer Mapbox](/assets/images/mapbox/mapbox-2.png)

Et le curseur de votre souris devrait changer lorsque vous passez sur le layer des communes.

### Ajout évènements au clic <a class="anchor" name="clickevent"></a>

Nous allons maintenant faire en sorte d'afficher certaines informations lorsque l'on clique sur un élément de notre nouveau layer.

Pour cela nous allons ajouter deux propriétés :
- *selectedElement* de type *GeoJsonProperties* qui contiendra les propriétés de l'élément sélectionné présent dans notre fichier json
- *selectedLngLat* de type *LngLat* qui correspond au coordonnées de notre clique.

Nous allons ajouter la fonction *onClick* qui prendra un paramètre de type *MapLayerMouseEvent*.

Pour commencer, importons ces 3 nouveaux types :
{% include code-header.html %}
```javascript
import { LngLat, MapLayerMouseEvent } from 'mapbox-gl';
import { GeoJsonProperties } from 'geojson';
```

Déclarons ensuite nos variables :
{% include code-header.html %}
```javascript
  selectedElement: GeoJsonProperties;
  selectedLngLat: LngLat;
```

Et créons notre fonction *onClick* :
{% include code-header.html %}
```javascript
  onClick(evt: MapLayerMouseEvent) {
    this.selectedLngLat = evt.lngLat;
    this.selectedElement = evt.features![0].properties;
  };
```

Dans *app.component.html* nous allons maintenant associer l'évènement *click* à notre fonction dans le composant du layer :
{% include code-header.html %}
```html
      <mgl-layer
        id="communes-rennes"
        type="fill-extrusion"
        [source]="communesRennes"
        [paint]="{
          'fill-extrusion-color': ['get', 'color'],
          'fill-extrusion-height': ['/', ['to-number', ['get', 'nbHabitant']], 100],
          'fill-extrusion-base': 0,
          'fill-extrusion-opacity': 0.5
        }"
        (mouseEnter)="cursorStyle = 'pointer'"
        (mouseLeave)="cursorStyle = ''"
        (click)="onClick($event)"
      ></mgl-layer>
```

Et enfin on va ajouter une popup Mapbox pour afficher nos informations :
{% include code-header.html %}
```html
      <mgl-popup *ngIf="selectedLngLat" [lngLat]="selectedLngLat">
        <div class="popup">
          Nombre d'habitants : <span [innerHTML]="selectedElement?.nbHabitant"></span>
        </div>
      </mgl-popup>
```

Vous devriez pouvoir avoir un rendu comme ci-dessous sur votre projet :

![Ajout d'un évènement au clic Mapbox](/assets/images/mapbox/mapbox-3.png)

## Conclusion <a class="anchor" name="conclusion"></a>

Mapbox permet une implémentation simple et rapide de vos jeux de données cartographiques et vous permet de les mettre plus en avant grâce à la 3D, sans nécessiter une compréhension poussée dans ces domaines.
Nous avons vu ici un exemple simple, mais il est possible d'avoir des jeux de données dynamiques, ajouter des animations etc...

Cependant la simplicité de la librairie vous limitera peut-être selon vos besoins.
En effet la librairie est développé par la société Mapbox et l'orientation des fonctionnalités à apporter est donc déterminée par les besoins clients de leur plateforme et non ceux de la communauté.
De plus la simplification de l'intégration dans Angular par exemple est elle maintenue par la communauté, donc pour certaines fonctionnalitées il est possible que vous soyez dépendant des besoins de Mapbox dans l'avenir et de l'implication de la communauté pour simplifier l'utilisation de ces nouvelles fonctionnalités.