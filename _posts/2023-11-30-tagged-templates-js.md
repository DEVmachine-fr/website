---
author: Fabien
title: Les tagged templates en JavaScript
categories: javascript js string template tags literals templating
---


# Les *tagged template* en JavaScript

## Introduction

Il y n'a pas longtemps, un de mes collègues est venu me poser cette question :

> &laquo; Ah tiens j'ai vu une syntaxe bizarre dans mon tuto sur Deno, je voulais te demander ce que c'était ? 
> Ils préfixent une _template string_ avec un nom de fonction, et je ne sais pas à quoi ça correspond dans le langage 🤔 &raquo;

Puis il me montre son écran :

```js
await conn.queryObject`SELECT * FROM users WHERE id = ${userId}`
```

Ah, ça ! Et bien ça s'appelle un _tagged template literal_. Mes explications et mes exemples sur le sujet ont eu l'air de répondre à ses questions, alors je me suis dit que ce serait une bonne idée d'en faire profiter tout le monde.

C'est parti ! 💪


> **Note** : Le [MDN](https://developer.mozilla.org) propose dans sa documentation des traductions françaises pour [cette fonctionnalité](https://developer.mozilla.org/fr/docs/Web/JavaScript/Reference/Template_literals), mais je préfère conserver les termes anglais pour la suite de cet article.
> Sachez toutefois pour votre culture qu'on parle respectivement de _gabarits étiquetés_ et de _littéraux de gabarits_ pour les termes _tagged template_ et _template literals_.

## Un petit rappel sur les *template literals*

Introduite avec la norme ES2015, cette fonctionnalité très attendue a enfin permis aux développeurs de construire des chaînes de caractères en y incorporant directement des expressions du langage.

Là où il fallait auparavant recourir à la **concaténation**, on dispose désormais d'une syntaxe plus lisible et moins verbeuse.

Avant : 
```js
const welcome = "Mon nom est " + name + ", j'ai " + age + " ans et aujourd'hui, je vais vous parler de " + topic
```

Après : 
```js
const welcome = `Mon nom est ${name}, j'ai ${age} ans et aujourd'hui, je vais vous parler de ${topic}`
```

Les *template literals* (ou _template strings_) sont délimités par des _backticks_ ` (ou _backquote_). 

> **Note** :  Sur les claviers de PC, le _backtick_ s'écrit à l'aide de la combinaison de touches `AltGr+7`. 
> **Attention !** Il s'agit d'une &laquo; _touche morte_ &raquo;, il faudra presser la touche **Espace** à la suite pour l'obtenir à la place d'une combinaison avec une voyelle (à, è, ì, etc.)
> Ça paraît compliqué, mais l'habitude viens vite, rassurez-vous 😉

### Chaînes de caractères multi-lignes

Autre fonctionnalité intéressante, les *templates literals* peuvent s'étaler sur plusieurs lignes, comme ceci :

```ts
const message = `Bienvenue 
chez moi, je m'appelle ${name},
je vous en prie, prenez place.`
// -> "Bienvenue\nchez moi, je m'appelle Fabien,\nje vous en prie, prenez place."
```
Bien entendu, le caractère de saut de ligne (`\n`) est ajouté automatiquement, mais on peut l'échapper comme n'importe quel autre caractère :

```js
const message = `Bienvenue \
chez moi`
// -> "Bienvenue chez moi"
```

### Interpolation d'expressions

On l'a dit, on peut maintenant appeler des expressions du langage à l'intérieur de la chaîne, via la syntaxe `${<expression>}` :

```js
const addition = (a, b) => `La somme ${a} + ${b} vaut ${a + b}`
```

Nom de variable, résultat d'une opération, appel de méthode, ... tout est possible.

De plus, les expressions sont automatiquement converties en chaîne de caractère, via un appel au constructeur `String`. 

Il faudra néanmoins faire attention à cette conversion avec les objets :

```js
const personne = { age: 42, gender: 'man' }
console.log(`Le contenu de l'objet est ${o}`)
// -> Le contenu de l'objet est [object Object]
```

Il est possible dans ce cas de définir sur l'objet une surcharge de la méthode `toString()`.

## Un *tagged template*, c'est quoi ?

Il est possible de &laquo; taguer &raquo; un _template literal_ à l'aide d'une _tag function_.

On peut utiliser cette fonction sur un *template literal* comme ceci :

```js
myTag`Bonjour ${name}, vous pouvez me contacter au ${phone}. Bonne journée.`
```

Quelle différence avec une fonction normale me demanderez-vous ? Pourquoi ne pas écrire simplement : 

```js
myTag(`Bonjour ${name}, vous pouvez me contacter au ${phone}. Bonne journée.`)
```

Et bien contrairement à une fonction normale, celle-ci est appelée par JavaScript et reçoit les différents constituants de la chaîne et non la chaîne résultante :

```js
function myTag(fragments, ...values) {
  // fragments = ["Bonjour ", ", vous pouvez me contacter au ", ". Bonne journée."]
  // values = ["Fabien", "06 00 00 00 00"]
  return ...
}
```

On voit ici qu'une _tag function_ est appelé avec deux arguments :
- un tableau de chaîne de caractères contenant les **fragments** du *template literal*, c'est-à-dire les **parties statiques** entourant les expressions
- une liste d'arguments variables (_varargs_) contenant les **valeurs des expressions**, qui constituent les parties dynamiques du littéral

![diagramme illustrant la séparation entre fragments et valeur](/assets/images/tagged-templates-js/fragments.png)

🚩 Le tableau `values` contient les valeurs avant leur conversion en chaîne, donc il est possible d'y retrouver des valeurs de tout type.

Le *template literal* n'est pas traité au moment où le _tag function_ est appelée : c'est la valeur de retour de celle-ci qui détermine la chaîne résultante.

On pourrait très bien imaginer un tag `privacy` qui cache toutes les données passées dans la chaîne : 

```js
const message = privacy`Bonjour ${name}, vous pouvez me contacter au ${phone}. Bonne journée.`
// -> message = "Bonjour xxx, vous pouvez me contacter au xxx. Bonne journée."
```

D'ailleurs, il n'est absolument pas obligatoire de renvoyer une chaîne, on peut renvoyer ce que l'on veut.

##  À quoi ça sert ?

Les tags permettent de personnaliser la façon dont les littéraux sont interprétés. 

On peut par exemple : 
- modifier la valeur d'une ou plusieurs expressions ou modifier les fragments avant de reconstruire la chaîne
- retourner un objet résultant d'un traitement prenant en entrée les fragments et les valeurs séparément

Cela va s'avérer particulièrement utile et puissant, en particulier lorsque l'on fait du **templating** pour un autre langage au sein du code JavaScript, pour du HTML, du CSS, du SQL, etc.

## Une _tag function_ de base : `String.raw`

Toujours depuis ES2015, il existe un _tag_ de base dans le langage : `String.raw`.

Celui-ci permet de définir des chaînes textuelles (aussi appelée _verbatim strings_), dans lesquelles les caractères de contrôle ne sont pas interprétés, et qui ne nécessitent donc aucun échappement. 

C'est particulièrement utile pour les chemins d'accès sous Windows par exemple, car cette déclaration : 

```js
const filename = "C:\\Users\\machin\\Documents"
```

peut être remplacé par celui-ci :

```js
const filename = String.raw"C:\Users\machin\Documents"
```

On peut aussi les utiliser pour éviter l'échappement de caractères spéciaux dans une `RegExp` créée dynamiquement à partir d'une chaîne.


## Comment ça marche ?

### Reconstruire une chaîne à partir des fragments et des valeurs

On a vu plus haut que la _tag function_ reçoit à la fois les fragments et les valeurs des expressions contenus dans les _template strings_.

Dans la plupart des cas, on va vouloir reconstruire une chaîne en recombinant ces éléments, après avoir apporté nos modifications. 

On va créé ici le _tag_ `noopTag` qui n'apporte pas de modifications et retourne le même résultat qu'un _template literal_ normal.

```js
function noopTag(fragments, values...) {
  return values.reduce((acc, value, i) => `${acc}${fragments[i]}${value}`, '') + fragments.slice(-1) 
}
```
Avant de rentrer dans le détail de cet algorithme, il faut noter que : 
- `fragments` compte toujours un élément de plus que `values` : logique puisque les fragments entourent les valeurs

```js
tag`Je m'appelle ${prenom}, j'ai ${age} ans.`
// fragments : "Je m'appelle "  |          | ", j'ai " |    | " ans."  <-- 3 fragments
//    values :                  | "Fabien" |           | 32 |          <-- 2 valeurs
```
- ce postulat est toujours vrai, même aux cas limites :

```js
// En fin de chaîne
tag`Je m'appelle ${prenom}`
// fragments : "Je m'appelle "  |          | ""   <-- 2 fragments
//    values :                  | "Fabien" |      <-- 1 valeur

// En début de chaîne
tag`${nbarticles} articles trouvés`
// fragments : "" |    | " articles trouvés"      <-- 2 fragments
//    values :    | 13 |                          <-- 1 valeur

// une seule valeur sans fragment
tag`${nombre}`
// fragments : "" |    | ""                       <-- 2 fragments
//    values :    | 42 |                          <-- 1 valeur 

// Aucune valeur
tag`Ceci est une phrase banal`
// fragments : "Ceci est une phrase banal"        <-- 1 fragment
//    values :                                    <-- 0 valeur 
```

On peut donc recombiner la chaîne comme suit :
- On utilise `reduce` sur le tableau de valeurs, puis on utilise l'indice courant pour récupérer l'élément correspondant dans le tableau des fragments (on itère sur les 2 tableaux en parallèle)
- On ajoute le dernier fragment en fin de chaîne

```js
tag`Je m'appelle ${prenom}, j'ai ${age} ans.`
// fragments : ["Je m'appelle ", ", j'ai ", " ans."]
//    values : ["Fabien", 32]

// --> fragments[0] + values[0] + fragments[1] + values[1] + fragments[2]
// --> "Je m'appelle Fabien, j'ai 32 ans."
```

Si on est amené à reconstruire régulièrement des chaînes dans nos _tags functions_, on peut créer une fonction utilitaire dédiée :

```js
function cook(fragments, values) {
  return values.reduce((acc, value, i) => `${acc}${fragments[i]}${value}`, '') + fragments.slice(-1)
}

function noopTag(fragments, values...) {
  return cook(fragments, values)
}
```

### Manipulation des valeurs 

Prenons un exemple simple avec la _tag function_ `highlight` :

```js
const text = highlight`
Bonjour, je m'appelle ${name}, je suis développeur logiciel
`
```

On veut mettre en évidence les valeurs injectées dans le *template*, avec une balise `<strong>` par exemple :

```js
function highlight(fragments, ...values) {
  const newValues = values.map(value => `<strong>${value}</strong>`)
  return cook(fragments, newValues)
}
```

On applique la transformation sur nos valeurs, en entourant chaque valeur avec la balise, puis on utilise notre fonction `cook` définie précédemment pour reconstruire la chaîne. Cela nous donne dans notre chaîne `message` : 

```js
"Bonjour, je m'appelle <strong>Fabien</strong>, je suis développeur logiciel"
```

Rien ne nous empêche d'ailleurs d'appliquer une transformation sur les fragments statiques de la chaîne.

### Rendre une _tag function_ paramétrable

On peut vouloir fournir un ou plusieurs paramètres supplémentaires à une _tag function_, pour pouvoir modifier son comportement. 

**Comment s'y prendre étant donné la syntaxe si particulière de ce type de fonction ?**

```ts
translate`Hello ${name}`
```

`translate` reste une fonction, donc comment peut-on la rendre paramétrable ? Et bien grâce à une fonction d'ordre supérieure ! 

```js
function translate(lang) {
  // On retourne une tag function
  return (fragments, ...values) => {
    // Dans le corps du tag, on peut accéder au paramètre de la fonction d'ordre supérieur
    return translateString(lang, fragments, values)
  }
}
```

Et voilà le travail 🤩 :

```js
translate('fr')`Hello ${name}`
```
La chaîne est taguée par la fonction que retourne l'appel à `translate` . Celle-ci est paramétrée grâce à l'argument du paramètre `lang` qui vaut ici `"fr"`.


## Cas d'usage

### Requêtes préparées

Les requêtes préparées sont un mécanisme que l'on retrouve couramment lorsque l'on communique avec une base de données relationnelle. 
Elles permettent entre autres d'écarter les risques d'injection de code malveillant dans des requêtes SQL.

Un exemple d'exécution d'une requête préparée en **Node.js** connecté à une base **PostgreSQL**

```js
const sql = 'INSERT INTO users(name, email) VALUES($1, $2)'
const values = ['Fabien', 'fabien@devmachine.fr']
 
await client.query(text, values)
```

On voit que notre requête est séparée en 2 composantes : 
* Le texte SQL de la requête, dans lequel l'emplacement des valeurs à injecter sont balisées par des marqueurs de substitution (`$1`, `$2`)
* Les valeurs que l'on veut injecter dans l'ordre à l'emplacement de ces marqueurs

**C'est parfait !** Séparer et rassembler les parties statiques et dynamiques d'une chaîne, c'est le principal intérêt des _tags functions_ :

```js
prepareQuery`INSERT INTO users(name, email) VALUES(${name}, ${email})`
```

Grâce à cette _tag function_, on écrit la requête de façon plus naturelle, dans un seul _template literal_, mais on va quand même maintenir la séparation **fragments**/**valeurs** sous la capot. 

Voici ce que pourrait donner son implémentation :

```js
function prepareQuery(fragments, ...values) {  
  const placeholders = values.map((_, index) => `$${index + 1}`)  // (1) 
  const cooked = cook(fragments, placeholders)                    // (2)
  return client.query(cooked, values)                             // (3)
}
```

Détaillons les étapes de cette fonction :

| Étape | Explication | Résultat |
|--|--|--|
| 1 | On créé le tableau `placeholders` à partir des valeurs  | `["$1", "$2"]` |
| 2 | On reconstruit la chaîne en remplaçant les valeurs par les *placeholders* | `"INSERT INTO users(name, email) VALUES($1, $2)"` |
| 3 | On fait appel à `query()` comme dans l'exemple plus haut, en lui passant la chaîne reconstituée et les valeurs originelles | _résultat de l'exécution de la requête_ |

J'ai décrit une implémentation naïve pour démontrer le principe, mais sachez que le driver **Deno** pour **PostgreSQL** propose des _tags functions_ similaires :

```js
const conn = await pool.connect()
const result = await conn.queryObject`SELECT * FROM users WHERE id = ${userId}`
await conn.queryArray`
  UPDATE posts SET 
    last_update_date = ${updateDate},
    message = ${message}
  WHERE user_id = ${userId}
`
```

Pas mal, non ? 😎

### Internationalisation (i18n)

Un autre exemple est le support de l'internationalisation (*i18n*) dans nos chaînes de caractères.

L'approche visant à utiliser des clés de traductions peut parfois se révéler fastidieuse. 
On peut proposer une alternative en utilisant des phrases dans une langue de référence comme clé de traduction, puis définir leurs traductions dans d'autres langues.

```js
const lang = 'fr'

// Définition des traductions
const translations = {
  fr: {
    "Hello {0}, how are you?": "Bonjour {0}, comment allez-vous ?"
  },
  es: {
    "Hello {0}, how are you?": "Hola {0}, ¿qué tal?"
  }
}

// ... plus loin dans le code
console.log(translate("Hello {0}, how are you?", "Fabien"))
```

Bien sûr, c'est un exemple simpliste, mais on voit que l'utilisation de la fonction `translate` n'est pas idéale, et nous oblige à séparer les parties statiques et dynamiques de la chaîne.

Ça tombe bien, je vous ai expliqué comment fonctionnent les _tags functions_, on va pouvoir s'en servir ! Voici comment : 

```js
const name = 'Fabien'
console.log(translate`Hello ${name}, how are you?`)
```

Avouez que c'est nettement plus sympa de l'écrire comme ça. 😍
Maintenons, voyons comment cela se matérialise sous le capot de notre _tag_ `translate` :

```js
function translate(fragments, values...) {
  const placeholders = values.map((_, index) => `{${index}}`)   // (1)
  const cooked = cook(fragments, placeholders)                  // (2)
  const translation = translations[lang][cooked]                // (3)
  const translatedFragments = translation.split(/{\d+}/)        // (4)
  return cook(translatedFragments, values)                      // (5)
}
```

| Étape | Explication | Résultat |
|--|--|--|
| 1 | On créé le tableau `placeholders` à partir des valeurs  | `["{0}"]` |
| 2 | On reconstruit la chaîne en remplaçant les valeurs par les *placeholders* | `"Hello {0}, how are you?"` |
| 3 | On a notre clé de traduction, on va donc récupérer la traduction correspondante dans la langue courante | `"Bonjour {0}, comment allez-vous ?"` |
| 4 | On refait le chemin inverse, on extrait les fragments de la chaîne traduite | `["Bonjour ", ", comment allez-vous ?"]` |
| 5 | On recombine les fragments de la traduction avec les valeurs à injecter pour obtenir la traduction finale | `"Bonjour Fabien, comment allez-vous ?"` |

D'ailleurs, si on veut rendre le tag paramétrable comme on l'a vu plus haut, on peut spécifier directement la langue ciblée : 

```js
function translate(lang) {
  return (fragments, values...) => {
    // ...
    // lang n'est plus une variable globale mais fait partie de la portée englobante
    const translation = translations[lang][cooked]
    // ...
  }
}
```

Ce qui nous permet de l'utiliser comme ceci : 

```js
translate('fr')`Hello ${name}, how are you?`
// "Bonjour Fabien, comment allez-vous ?"
translate('es')`Hello ${name}, how are you?`
// "Hola Fabien, ¿qué tal?"
```

### Formatage de valeurs 

On peut aussi imaginer des _tags functions_ permettant de personnaliser le formatage des valeurs passées dans une chaîne.

```js
const totalAmount = 3415.63
currency`Valeur totale du panier : ${totalAmount}`
// "Valeur totale du panier : 3 415,637 €"
```

Ici, on veut formater les valeurs monétaires grâce à notre _tag function_ `currency`

```js
function formatCurrency(value, locale = 'fr-FR', currency = 'EUR') {
  // 💡 Le saviez-vous ? ECMAScript propose une API d'internationalisation normalisée
  // qui permet notamment de gérer les problématiques de formatage de nombres
  return new Intl.NumberFormat(locale, { style: 'currency', currency: 'EUR' }).format(
    value,
  ),
}

function currency(fragments, ...values) {
  const formattedValues = values.map(value => {
    // Formatage personnalisée pour tous les valeurs de type nombres
    if (typeof value === 'number' && !Number.isNaN(value)) {
      return formatCurrency(value)
    }
    return value
  })
  return cook(fragments, formattedValues)
}
```

> *On pourrait améliorer ce tag en le rendant paramétrable pour spécifier des options de formatage, comme par exemple un identifiant de langue ou de monnaie.*

### Bibliothèques reposant sur les _tags functions_

 - La bibliothèque **lit-html** intégrée au framework **Lit** permet de définir des *templates* HTML de composants grâce à la _tag function_ `html`.

```js
const todos = ['Tâche 1','Tâche 2']
const todoListTemplate = html`
<ul>
  ${todos.map(todo => html`<li>${todo}</li>`)}
</ul>
`
render(todoListTemplate(todos), document.body)
``` 

🌎 Lien du projet : [Github](https://github.com/lit/lit/tree/main/packages/lit-html)

 - La bibliothèque **styled-component** permet aux développeurs React de créer des composants et des éléments du DOM en leur attribuant directement du code de style CSS.

```js
const Title = styled.h1`
  font-size: 1.5em;
  text-align: center;
`
render(<Title>Titre de la page</Title>)
```

🌎 Lien du projet : [Site web](https://styled-components.com)

## Conclusion 

Dans cet article, on a vu ce que sont les _tags functions_ et comment elles peuvent se combiner au _template literal_ pour adresser certaines problématiques de _templating_.

On a d'abord replacer un peu le contexte en rappelant ce qu'étaient les _templates literals_ en JavaScript. Puis on a expliqué l'utilité des _tags functions_ et détailler leur fonctionnement à l'aide de nombreux exemples.

On a enfin présenté des cas d'usages dans lesquels cette fonctionnalité peut s'illustrer et comment cela est mis en place dans certaines bibliothèques de fonctions JavaScript.

J'espère que j'ai pu éclairé vos lanternes sur ce sujet.

Je vous remercie de votre attention ! 🙏 😊

## Bibliographie : 

J'adresse mes remerciements aux auteurs de ces articles et de ces bibliothèques qui m'ont inspiré pour la rédaction de cet article :
* [*Template Literals and a Practical Use of Tagged Templates in JavaScript*  par **Sanjay Bhavnani**](https://javascript.plainenglish.io/template-literals-and-a-practical-use-of-tagged-templates-58526d525d72)
* [*Advanced String Manipulation with Tagged Templates In JavaScript* par **Alex Khomenko**](https://claritydev.net/blog/javascript-advanced-string-manipulation-tagged-templates)
* [Dépôt Github de la bibliothèque **lit-html**](https://github.com/lit/lit/tree/main/packages/lit-html)
* [*Les template literals en ES2015+* par **Christophe Porteneuve**](https://delicious-insights.com/fr/articles-et-tutos/js-template-literals)
* [*Understanding Tagged Template Literal in JS* par **Rafael Leitão**](https://dev.to/carlosrafael22/understanding-tagged-template-literal-in-js-49p7)
* [*Magic of Tagged Templates Literals in JavaScript?* par **Hemil Patel**](https://patelhemil.medium.com/magic-of-tagged-templates-literals-in-javascript-e0e2379b1ffc)
