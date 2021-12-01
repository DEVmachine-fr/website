---
author: Gwenolé
title: Implémentation Three.js dans un projet Vue.js
categories: Three.js Vue.js
---


Nous vous partageons ici un tutoriel pour pouvoir débuter simplement l’implémentation de Three.js dans un projet Vue.js avec comme illustration l’affichage de modèles 3D dans des vignettes produits.

- [Introduction](#introduction)
- [Three.js, kézako ?](#kesaco)
- [Initialisation du projet Vue.js](#initProject)
- [Création des composants](#createComponents)
- [Intégration de Three.js](#integration)
    - [La scène](#scene)
    - [Le renderer](#renderer)
    - [La caméra](#camera)
    - [Le contrôleur](#controller)
    - [La lumière](#lights)
    - [Les modèles 3D](#models)
- [Ressources](#ressources)

## Introduction <a class="anchor" name="introduction"></a>

Nous verrons tout d'abord comment créer le projet en Vue.js avec les composants dont nous aurons besoin. Le projet aura comme structure :

- components
    - navigation-header
      - `navigation-header.vue` : bandeau de navigation en haut de page (à titre d'exemple).
    - product-thumbnail
      - `product-thumbnail.vue` :  vignette produit avec les différentes informations liées à celle-ci.
    - product-view
      - `product-view.vue` :  vue 3D du produit.
- views
    - product-list
      - `product-list.vue` : affichage de la liste des produits.

Nous présenterons ensuite plusieurs notions 3D lors de leur intégration avec Three.js :

- la scène et son rendu
- la caméra et son contrôle
- la gestion de la lumière

## Three.js, kézako ? <a class="anchor" name="kesaco"></a>

Three.js est une librairie Javascript qui permet d'intégrer de la 3D dans votre site web. Cette libraire permet de créer des rendus en WebGL, CSS3D et SVG. Vous pouvez trouver des exemples sur les nombreuses possibilités qu'offre Three.js [ici](https://threejs.org/examples/).

Nous allons nous intéresser à du rendu WebGL pour ce tutoriel.

## Initialisation du projet Vue.js <a class="anchor" name="initProject"></a>

Tout d'abord, nous allons devoir installer vue-cli via `npm` si cela n'est pas déjà fait :
{% include code-header.html %}
```
npm install -g @vue/cli
```
Vous pouvez vérifier la bonne installation en affichant la version de Vue.js installée :
{% include code-header.html %}
```
vue --version
```
Nous allons ensuite générer notre projet :
{% include code-header.html %}
```
vue create my-project-name
```
Nous garderons le paramétrage par défaut pour notre exemple (libre à vous de le modifier pour votre projet).

Pour ce qui est des dépendances, nous utiliserons bootstrap-vue pour faciliter la mise en page et Three.js :
{% include code-header.html %}
```
npm install --save bootstrap-vue
npm install --save three
```
## Création des composants Vue.js <a class="anchor" name="createComponents"></a>

Pour ce tutoriel, nous allons uniquement intégrer des modèles gltf, ce format étant conseillé pour le web car moins lourd et donc plus rapide à charger. Si vous souhaitez charger d’autres formats, je vous invite à consulter les exemples de **Three.js** sur les imports des différents formats et adapter le code ci-dessous en fonction.

Nous allons tout d'abord créer un composant **navigation-header.vue** dans un dossier _components/navigation-header_. Le code ci-dessous est un simple copier-coller d'un exemple de barre de navigation de la documentation **bootstrap** :
{% include code-header.html %}
```html
<template>
<div>
  <b-navbar toggleable="lg" type="dark" variant="info">
    <b-navbar-brand href="#">NavBar</b-navbar-brand>

    <b-navbar-toggle target="nav-collapse"></b-navbar-toggle>

    <b-collapse id="nav-collapse" is-nav>
      <b-navbar-nav>
        <b-nav-item href="#">Link</b-nav-item>
        <b-nav-item href="#" disabled>Disabled</b-nav-item>
      </b-navbar-nav>

      <!-- Right aligned nav items -->
      <b-navbar-nav class="ml-auto">
        <b-nav-form>
          <b-form-input size="sm" class="mr-sm-2" placeholder="Search"></b-form-input>
          <b-button size="sm" class="my-2 my-sm-0" type="submit">Search</b-button>
        </b-nav-form>

        <b-nav-item-dropdown text="Lang" right>
          <b-dropdown-item href="#">EN</b-dropdown-item>
          <b-dropdown-item href="#">ES</b-dropdown-item>
          <b-dropdown-item href="#">RU</b-dropdown-item>
          <b-dropdown-item href="#">FA</b-dropdown-item>
        </b-nav-item-dropdown>

        <b-nav-item-dropdown right>
          <!-- Using 'button-content' slot -->
          <template #button-content>
            <em>User</em>
          </template>
          <b-dropdown-item href="#">Profile</b-dropdown-item>
          <b-dropdown-item href="#">Sign Out</b-dropdown-item>
        </b-nav-item-dropdown>
      </b-navbar-nav>
    </b-collapse>
  </b-navbar>
</div>
</template>
<script>
export default {
  name: "NavigationHeader",
};
</script>
```
Passons maintenant au composant qui contiendra l'affichage 3D de notre modèle, qui sera le composant **product-view.vue** dans _components/product-view_. Nous l'initialiserons juste ici avec quelques propriétés et nous reviendrons dessus par la suite. 
{% include code-header.html %}
```html
<template> </template>
<script>
export default {
    name: "ProductView",
    props: {
        containerId: {
            type: String,
            required: true
        },
        modelSettings: {
            type: Object,
            required: true
        }
    }
}
</script>
```
**containerId** sera l'id du contenant du composant dont on aura besoin pour connaître les dimensions
**modelSettings**. Il contiendra les différentes informations nécessaires à l'affichage du modèle dans **Three.js**

Nous allons intégrer ce dernier composant dans un composant vignette **product-thumbnail.vue** dans _components/product-thumbnail_. Ce composant affichera la visualisation 3D ainsi qu'un titre et une description :
{% include code-header.html %}
```html
<template>
  <div class="card shadow-sm">
    <div class="product-content">
      <div class="bd-placeholder-img card-img-top product-thumbnail" :id="thumbnailId">
        <product-view
          :container-id="thumbnailId"
          :model-settings="product.obj3DSettings"
        ></product-view>
      </div>
      <div class="card-body">
        <div class="card-text">
          <div class="title">{{ product.title }}</div>
          {{ product.description }}
        </div>
        <div class="d-flex justify-content-between align-items-center">
          <div class="btn-group">
            <button class="btn btn-sm btn-outline-secondary" type="button">Nous contacter</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import ProductView from "../product-view/product-view";

export default {
  name: "ProductThumbnail",
  components: {
    ProductView
  },
  props: {
    product: {
      type: Object,
      required: true
    },
    thumbnailId: {
      type: String,
      required: true
    }
  }
};
</script>


<style>
.product-thumbnail {
  width: 100%;
  height: 400px;
}
.title {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 50px;
  text-align: center;
  border-bottom: 1px solid #ccc;
}
</style>
```

Ensuite, nous allons créer dans _views/product-list_ le composant **product-list.vue**. Ce composant intégrera le composant de navigation et créera une liste de composants **product-thumbnail**. Pour cette démonstration, nous initialiserons cette liste directement dans le composant.

Pour les modèles, nous récupérons les voitures sur sketchfab et un modèle de casque présent dans les exemples de Three.js ([lien en fin d'article](#ressources)).

Nous aurons pour chaque modèle une propriété **obj3DSettings** pour l'affichage 3D, ayant comme sous-propriétés :
* `link` : lien vers le modèle gltf.
* `cameraPosition` : position de la caméra. Certains modèles peuvent être plus grands ou plus petits, il est donc intéressant de pouvoir éloigner ou approcher la caméra par défaut en fonction du modèle.
* `scale` : échelle du modèle de base. Si vous chargez des modèles venant de différentes sources, il est possible que les modèles ne soient pas à la même échelle. Vous pouvez régler ce problème en réglant la propriété scale (exemple : un scale de 2 doublera la taille de votre modèle, un scale de 0.5 le divisera par 2).
{% include code-header.html %}
```html
<template>
<div>
<navigation-header></navigation-header>
<div class="container" id="product-list">
  <div class="row row-cols-1 row-cols-sm-2 row-cols-md-2 g-3">
    <div
      class="col p-5"
      v-for="(product, index) in productList"
      v-bind:key="'product-item-' + product.title.replace(' ', '-')"
    >
      <product-thumbnail
        v-bind:key="product.title"
        :product="product"
        :thumbnail-id="'thumbnail-' + index"
      ></product-thumbnail>
    </div>
  </div>
</div>
</div>
</template>

<script>
import ProductThumbnail from "../../components/product-thumbnail/product-thumbnail";
import NavigationHeader from "../../components/navigation-header/navigation-header";

export default {
name: "ProductList",
components: {
  ProductThumbnail,
  NavigationHeader
},
data() {
  return {
    productList: [
      {
        title: "helmet example",
        description: `Donec vestibulum mauris eu quam rhoncus, sed iaculis urna feugiat. Maecenas vehicula nisl elit, quis. `,
        obj3DSettings: {
          link: "/static/assets/models/gltf/helmet/DamagedHelmet.gltf",
          cameraPosition: [-1.8, 0.6, 2.7]
        }
      },
      {
        title: "car example",
        description: `In nec fringilla neque, non ullamcorper nibh. Suspendisse potenti. Pellentesque luctus pulvinar hendrerit. In interdum.`,
        obj3DSettings: {
          link: "/static/assets/models/gltf/car/nissan-skyline/scene.gltf",
          cameraPosition: [-0.8, 0.6, 0.7],
          scale: 0.0005
        }
      },
      {
        title: "car example 2",
        description: `Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed tortor elit, convallis ac orci non.`,
        obj3DSettings: {
          link:
            "/static/assets/models/gltf/car/chevrolet-corvette/scene.gltf",
          cameraPosition: [-1.8, 0.6, 2.7],
          scale: 0.002
        }
      }
    ]
  };
}
};
</script>
```
Nous allons finalement modifier App.js pour importer **product-list.vue** :
{% include code-header.html %}
```html
<template>
  <div id="app">
    <product-list />
  </div>
</template>

<script>
import ProductList from "./views/product-list/product-list";

export default {
  name: "App",
  components: {
    ProductList
  }
};
</script>

<style>
#app {
  font-family: "Avenir", Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
}
</style>
```
Vous devriez maintenant avoir ceci lorsque vous lancez votre projet :

![projet après création des composants](/assets/images/threejs/threejs-1.png)

## Intégration de Three.js <a class="anchor" name="integration"></a>

Passons maintenant au coeur du sujet. Retournons donc dans **product-view** et commençons par importer 3 éléments :
{% include code-header.html %}
```html
<template> </template>
<script>
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader";
...
```
Le premier élément est tout simplement la librairie Three.js.
**OrbitControls** - récupéré depuis les exemples de la libraire - nous permettra de déplacer la caméra de manière circulaire autour d'un point (l'orbite de la caméra) tout en gardant la caméra dirigée vers ce point.
**GLTFLoader** nous permettra tout simplement de charger nos éléments aux formats **GLTF**

Ajoutons ensuite certaines propriétés dans **data** :
{% include code-header.html %}
```javascript
export default {
name: "ProductView"
data() {
    return {
        scene: undefined,
        camera: undefined,
        renderer: undefined
    };
},
...
```
* `scene` représente la scène 3D. La scène est l'élément de base, une boite vide dans laquelle nous pourrons placer nos différents éléments dans l'espace en 3 voire 4 dimensions si l'on veut ajouter des animations, la quatrième dimension étant le temps.
* `camera` sera la caméra que l'on ajoutera dans la scène 3D. C'est la caméra qui détermine quelle partie de la scène sera rendue à l'affichage, en fonction notamment de sa position et de sa direction.
* `renderer` est l'élément qui générera l'affichage de la scène 3D du point de vue de la caméra.

Nous allons maintenant ajouter deux méthodes à notre composant. Tout d'abord la fonction **renderScene** qui lancera la génération du rendu pour l'affichage : 
{% include code-header.html %}
```javascript
methods: {
    renderScene() {
      this.renderer.render(this.scene, this.camera);
    },
    ...
```
    
Juste en dessous nous ajouterons la fonction **init**, qui créera tous les éléments dont nous avons besoin pour le rendu :
{% include code-header.html %}
```javascript
init() {
  ...
```

### La scène <a class="anchor" name="scene"></a>

Tout d'abord, nous allons créer simplement la scène 3D. Nous allons préciser que l'on ne veut pas de couleur de fond pour notre scène, ainsi nous aurons tout simplement la couleur en fond de la page web :
{% include code-header.html %}
```javascript
this.scene = new THREE.Scene();
this.scene.background = null;
```

### Le renderer <a class="anchor" name="renderer"></a>

Nous allons ensuite générer le renderer :
{% include code-header.html %}
```javascript
this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
```
Nous allons préciser l'encodage des couleurs en sortie :
{% include code-header.html %}
```javascript
this.renderer.outputEncoding = THREE.sRGBEncoding;
```
Pour éviter une déformation de l'image, nous allons préciser le pixel ratio de l'écran :
{% include code-header.html %}
```javascript
this.renderer.setPixelRatio(window.devicePixelRatio);
```
Nous allons ensuite configurer la taille dans laquelle doit être fait le rendu et  ajouter ensuite le renderer dans le DOM. Dans notre cas on souhaite afficher le rendu dans le contenant de **product-view**, on prendra donc le DOM de celui-ci pour déterminer la taille et insérer le renderer :
{% include code-header.html %}
```javascript
const container = document.getElementById(this.containerId);
this.renderer.setSize(container.offsetWidth, container.offsetHeight);
container.appendChild(this.renderer.domElement);
```
### La caméra <a class="anchor" name="camera"></a>

Nous allons ensuite créer la caméra et la positionner à la position enregistrée dans **modelSettings.cameraPosition** :
{% include code-header.html %}
```javascript
this.camera = new THREE.PerspectiveCamera(
    45,
    container.offsetWidth / container.offsetHeight,
    0.25,
    20
);
this.camera.position.set(this.modelSettings.cameraPosition[0], this.modelSettings.cameraPosition[1], this.modelSettings.cameraPosition[2]);
```
Les champs pour la création de la caméra sont :
* `fov (field of view)` : degré du champ de vision de la caméra.
* `ratio` : ratio entre la largeur du rendu et sa hauteur. Ici on prendra les propriétés du contenant du rendu pour éviter une déformation de l'image.
* `near` : distance minimum pour qu'un objet soit visible au rendu.
* `far` : distance maximum pour qu'un object soit visible au rendu.

### Le contrôleur <a class="anchor" name="controller"></a>

Nous allons maintenant attribuer des contrôles à la caméra pour pouvoir bouger celle-ci :
{% include code-header.html %}
```javascript
const controls = new OrbitControls(this.camera, this.renderer.domElement);
controls.minDistance = 2;
controls.maxDistance = 5;
// controls.enablePan = false;
controls.target.set(0, 0, 0);
controls.addEventListener("change", this.renderScene);
```
Ici, on nomme target ou cible le point autour duquel la caméra tournera et vers lequel elle est toujours orientée.

* controls.minDistance est la distance minimum entre la cible et la caméra. Cela permet d'avoir un zoom maximum en somme
* controles.maxDistance est la distance maximum entre la cible et la caméra. Cela permet donc d'avoir un zoom minimum
* controles.target.set permet de définir la position 3D de la cible
* l'event listener permet d'avoir à chaque mouvement de la caméra un nouveau rendu depuis la nouvelle position de celle-ci

### La lumière <a class="anchor" name="lights"></a>

Nous allons passer maintenant aux lumières. Nous allons implémenter 2 types de lumières :
* `la lumière directionnelle` : cette lumière éclaire tous les objets de la scène non masqués par un autre objet (quelque soit la distance) avec des rayons ayant une direction précise (tous les rayons sont donc parallèles entre eux). Ce type de lumière s'apparente à la lumière du soleil.
* `le point de lumière` : un point de lumière émet de la lumière depuis un seul point dans toutes les directions. Ce type de lumière s'apparente à celle d'une ampoule.

Ci-dessous une liste non-exhaustive de types de lumières que l'on peut avoir et comment celles-ci influent sur la scène et les objets :

![différents types de lumières](https://docs.arnoldrenderer.com/download/attachments/38175890/image2019-7-23%2014%3A41%3A48.png?version=1&modificationDate=1563885709000&api=v2)

Il est important d'avoir plusieurs sources de lumières à différentes positions et de différentes couleurs pour avoir un meilleur rendu, car nous sommes constamment exposés à différentes sources de lumières, chaque objet renvoyant lui même une partie de la lumière qu'il reçoit.

Nous allons donc ajouter à notre scène une lumière directionnelle et 3 points de lumière répartis à différentes positions, chacune de ses sources avec une couleur légèrement différente :
{% include code-header.html %}
```javascript
const directionalLight = new THREE.DirectionalLight(0xffffff, 2);
directionalLight.position.set(0, 1, 0);
directionalLight.castShadow = true;
this.scene.add(directionalLight);
const light = new THREE.PointLight(0xffffcc, 1);
light.position.set(0, 600, 1000);
this.scene.add(light);
const light2 = new THREE.PointLight(0xe6f7ff, 1);
light2.position.set(1000, 200, 0);
this.scene.add(light2);
const light3 = new THREE.PointLight(0xfff2e6, 1);
light3.position.set(0, 200, -1000);
this.scene.add(light3);
const light4 = new THREE.PointLight(0xc4c400, 1);
light4.position.set(-1000, 600, 1000);
this.scene.add(light4);
```
### Les modèles 3D <a class="anchor" name="models"></a>

Enfin, nous allons charger notre modèle dans la scène. Une fois chargé, nous allons le positionner au niveau de la cible du contrôleur de la caméra pour que celle-ci tourne autour de l'objet, et si la propriété scale existe, on appliquera une mise à l'échelle avec celle-ci. On fait un premier rendu de l'objet (sinon on n'aura notre premier rendu que lorsque l'on bougera la caméra) : 
{% include code-header.html %}
```javascript
let loader = new GLTFLoader();
loader.load(
    this.modelSettings.link,
    data => {
        var object = data.scene;
        object.position.set(0,0,0);
        if(this.modelSettings.scale) object.scale.set(this.modelSettings.scale, this.modelSettings.scale,     this.modelSettings.scale);
        this.scene.add(object);
        this.renderScene();
    }
);
```
Et voilà ! Vous devriez désormais voir la liste de vos produits avec leur affichage en 3D : 

![résultat finale](/assets/images/threejs/threejs-2.png)


Attention cependant ! Bien que l'affichage de tous vos modèles en 3D directement depuis la liste des produits puisse être intéressant, cela a un coût non négligeable sur le temps de chargement, aussi vaut-il mieux réserver cela pour la fiche détaillée du produit ou prévoir un chargement asynchrone et ne charger qu'une image dans un premier temps par exemple.

## Ressources <a class="anchor" name="ressources"></a>

* [corvette by d2epetto](https://sketchfab.com/3d-models/chevrolet-corvette-c7-2b509d1bce104224b147c81757f6f43a)
* [nissan skyline](https://sketchfab.com/3d-models/nissan-skyline-gt-r-c110-kenmeri-72-1a950b81ee274a0eb8014bd84ba047f5)
* [damage helmet demo](https://threejs.org/examples/?q=gltf#webgl_loader_gltf)
* [Lien github du code source](https://github.com/gerard-g-dm/vue-threejs)