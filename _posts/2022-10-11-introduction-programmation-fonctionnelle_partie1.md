---
author: Fabien
title: Introduction à la programmation fonctionnelle en JavaScript, partie I
categories: js fp functional programming ramda node
---


Dans cette série d'article, nous allons voir ce qu'est la programmation fonctionnelle, comment elle peut nous permettre d'écrire de meilleurs programmes et enfin comment en faire en JavaScript.

# Introduction à la programmation fonctionnelle en JS, partie I

- [Introduction à la programmation fonctionnelle en JS, partie I](#introduction-à-la-programmation-fonctionnelle-en-js-partie-i)
  - [Introduction](#introduction)
  - [La programmation fonctionnelle, c'est quoi ?](#la-programmation-fonctionnelle-cest-quoi-)
  - [Grands principes](#grands-principes)
    - [Limiter les effets de bord](#limiter-les-effets-de-bord)
    - [Écrire des fonctions pures](#écrire-des-fonctions-pures)
    - [Implications](#implications)
  - [Concepts majeures](#concepts-majeures)
    - [La currification (ou *currying*)](#la-currification-ou-currying)
    - [La composition de fonctions](#la-composition-de-fonctions)
    - [Les fonctions d'ordre supérieur](#les-fonctions-dordre-supérieur)
    - [Map, filter et reduce](#map-filter-et-reduce)
      - [Filter](#filter)
      - [Map](#map)
      - [Reduce](#reduce)
      - [Et pourquoi pas forEach ?](#et-pourquoi-pas-foreach-)
  - [Dans le prochain épisode ...](#dans-le-prochain-épisode-)

**Note importante avant de commencer** : Il est important de garder à l'esprit que je ne fais pas de programmation fonctionnelle habituellement dans mon métier, et que ceci est davantage une retranscription de ma découverte qu'un guide exhaustif. L'idée de l'article est davantage de proposer une introduction adressée à des gens totalement novices à ce type de programmation.

## Introduction

Alors que je cherchais des infos sur Lodash, je suis tombé sur cet article : 

&laquo; _[Dipping a toe into functional JS with lodash/fp](https://simonsmith.io/dipping-a-toe-into-functional-js-with-lodash-fp)_ &raquo; du blog de **Simon Smith**

J'ai voulu m'intéresser d'un peu plus près à la programmation fonctionnelle, car j'en entends souvent parler lorsque je fais ma veille. J'ai fait un peu d'OCaml pendant mon cursus, mais cela remonte à loin et je n'en avais presque plus aucun souvenir.

L'idée de cet article est de partager avec vous ma découverte de la programmation fonctionnelle dans un langage avec lequel je travaille quotidiennement, JavaScript. 

Après vous avoir présenté les notions importantes, je vous montrerai comment je les ai appliquées en convertissant une API d'exemple codé de manière impérative vers son équivalent en programmation fonctionnelle.

## La programmation fonctionnelle, c'est quoi ?

La programmation fonctionnelle est un paradigme de programmation, au même titre que la programmation impérative ou la programmation orientée objet :

- il permet de programmer de manière déclarative : on décrit ce que fait le traitement, et non pas comment il le fait
- une application est une composition de plusieurs fonctions, au sens mathématique du terme
- l'exécution d'un calcul correspond à l'évaluation d'une fonction
- on n'admet pas le changement d'état

## Grands principes

### Limiter les effets de bord

Le premier grand principe de la programmation fonctionnelle est de **limiter** au maximum l'introduction d'effets de bords (_side effects_) dans notre programme. Nos traitements, représentés par des fonctions, doivent éviter d'altérer le fonctionnement des autres fonctions du programme.

Par effet de bord, on peut notamment citer : 

- la modification de variables globales/locales partagées entre plusieurs fonctions
- la mutation des objets
- la modification de la valeurs des arguments 
- les opérations d'entrées/sorties (I/O)

On comprend vite ici pourquoi qu'on ne pourra que limiter ces effets et que l'intégralité de notre programme ne pourra pas être fonctionnellement pur à 100%. Dans la mesure où un programme interagit avec l'extérieur via les appels I/O (saisie utilisateur, base de données, fichiers), il introduit et/ou subit inévitablement des effets de bords.

Toutefois, en programmation fonctionnelle on essaie d'identifier explicitement ces effets, et de les déplacer vers l'extérieur de notre architecture, de sorte que nos traitements métiers, au centre de l'application, en soient exempts le plus possible.

### Écrire des fonctions pures

La pureté d'une fonction est déterminée par les critères suivants : 

- **le déterminisme** : une fonction appelée avec la même combinaison d'argument doit toujours renvoyer le même résultat. Ce comportement permet notamment d'introduire des mécanismes de mémoïsation, permettant de mettre en cache le résultat d'un traitement coûteux.
- **la transparence référentielle** : une fonction doit être entièrement remplaçable par le résultat de son évaluation
- **la totalité** : une fonction prenant un argument de type `A` (on parle de *domaine*) et renvoyant un résultat de type `B` (*codomaine*) doit renvoyer systématiquement un résultat de type `B` pour l'ensemble du domaine (toute les valeurs possibles portées par le type `A`).

Une fonction est donc pure si elle remplit ces trois critères, une fonction déterministe mais qui n'est pas totale n'est pas pure.

Notons que l'impureté dans un programme est contaminante : toute fonction supposément pure devient impure si elle appelle une fonction impure. Bien évidemment pour des raisons techniques, et parce que notre programme doit forcément interagir avec l'extérieur, il est impossible d'écrire un programme dépourvu de code impur.

### Implications

Toutes ces règles apportent leur lot de restriction, ce qui amène à éviter au maximum l'emploi de beaucoup d'instructions fourni par JavaScript, notamment : 

* **la déclaration de variable** (`var` et `let`) : on préfère utiliser `const` pour prévenir la réaffectation, même si cela n'empêche pas la mutation des objets.
* **les boucles** (`while`, `for`, `for…of`, etc.) : dans la mesure où leur fonctionnement repose sur des variables locales pouvant induire des effets de bords, on préfère utiliser la récursivité ou les fonctions d'ordre supérieur `map`, `filter` et `reduce`.
* **les fonctions sans résultat**
* **la mutation d'objet** : on préfère recréer une copie de l'objet avec la modification
* **la mutation de tableaux** et d'autres collections (`Map` et `Set`)
* **les exceptions** : on verra comment gérer les erreurs d'une autre façon

On va également éviter autant que possible d'intégrer certains éléments impurs par nature à nos fonctions :

* tous les appels **d'entrée / sortie** (I/O)
* la génération de **nombres pseudo-aléatoires**
* le **temps présent**

## Concepts majeures

### La currification (ou *currying*)

La currification est un concept clé de la programmation fonctionnelle, qui consiste à transformer une fonction à **n** arguments en **n** fonctions à **un** argument.

Elle permet de mettre en oeuvre l'application partielle, notamment en créant à la volée des fonctions avec des arguments préalablement renseignés.

L'idée est que lorsque l'on appelle une fonction currifiée avec un nombre d'argument inférieur à celui attendu, celle-ci renvoie une fonction attendant le nombre d'argument restant.

Si on prend l'exemple de l'addition :

```js
const add = (a, b) => a + b
```

La version currifiée serait définie comme ceci en JavaScript :

```js
const addCurry = a => b => a + b
```

Dès lors, on peut définir une fonction `addThree` qui serait une application partielle de la fonction `add` qui ajouterait 3 à l'argument `b` :

```js
const addThree = addCurry(3)

addThree(2) // => 5
```

La fonction currifiée renvoyant elle-même une fonction, on peut chaîner les arguments comme ceci :

```js
add(3, 2) // => 5
addCurry(3)(2) // => 5
```

Nous le verrons, il existe des bibliothèques de programmation fonctionnelle, notamment **Ramda**, qui proposent des fonctions permettant de "*currifier*" automatiquement nos propres fonctions.

```js
const addCurry = R.curry(add)
```

### La composition de fonctions

La composition est un autre concept important de la programmation fonctionnelle. L'idée est la même qu'en mathématique :

![equation composition](/assets/images/prog-fonctionnelle-js/composition.svg)

Voyons un exemple en composant 3 fonctions :

```js
const add  = b => a => a + b
const mult = b => a => a * b
const pow  = b => a => a ** b

const double = mult(2)
const inc = add(1)
const square = pow(2)

const fn = R.compose(square, inc, double)
const fn = n => ((n * 2) + 1) ** 2

fn(5) // => 121
```

À noter que comme en mathématique, l'application des composantes se fait de droite à gauche. Ici, on doublera d'abord la valeur avant de l'incrémenter, puis de l'élever au carré.

**Important** : la composition de fonction n'est pas commutative, l'ordre a son importance.

### Les fonctions d'ordre supérieur

Une fonction est dite d'ordre supérieur si elle satisfait au moins une des deux règles suivantes :

- elle prend une fonction en paramètre
- elle renvoie une fonction

Les fonctions currifiées ainsi que les méthodes `map()`, `filter()` et `reduce()` sont des *fonctions d'ordre supérieur*.

### Map, filter et reduce

Ces trois fonctions sont typiques de la programmation fonctionnelle et agissent sur les tableaux ou autres itérables.

En JavaScript, le prototype de l'objet `Array` disposent de ces méthodes, mais nous allons utiliser les équivalents proposées par la bibliothèque **Ramda**.

#### Filter

La fonction `filter()` prend en paramètre un **prédicat**, c'est-à-dire une fonction prenant en paramètre un objet de la collection et renvoyant un booléen.

Elle renverra une nouvelle collection ne contenant que les éléments ayant satisfait le prédicat.

Prenons un exemple :

```js
const students = [
  { name: 'Karine Deckow', age: 31 },
  { name: 'Pansy Predovic', age: 23 },
  { name: 'Noe Medhurst', age: 20 },
  { name: 'Vidal Metz', age: 17 },
  { name: 'Cayla Streich', age: 42 }
]
```

On veut filter les étudiants pour ne garder uniquement que ceux âgés de plus de 2 ans. Il nous faut un prédicat à passer à `filter()`.

```js
const olderThan25 = student => student.age > 25
```

Mais on peut faire mieux ! On peut définir une fonction d'ordre supérieure qui permet de rendre le prédicat générique vis à vis de l'âge.

```js
const olderThan = age => student => student.age > age
```

Ensuite, je peux appliquer `filter()`. On choisit d'utiliser Ramda, ce qui nous permet de créer notre fonction finale qui filtre les étudiants ayant plus de 25 ans.

```js
const keepOlderThan25 = R.filter(olderThan(25))

keepOlderThan25(students) // ->
[ 
  { name: 'Karine Deckow', age: 31 },
  { name: 'Cayla Streich', age: 42 }
]
```

La fonction `R.filter()` de **Ramda** est currifiée automatiquement, ce qui permet de réaliser l'application partielle du traitement : notre fonction `keepOlderThan25()` attends donc son argument final, qui est la collection.

Note : les fonctions proposées par les bibliothèques de programmation fonctionnelle adoptent volontairement les caractéristiques suivantes :

- elles sont currifiées automatiquement
- l'argument correspondant à la donnée est positionné en dernier dans leur signature
  De cette façon, on peut composer notre traitement en une fonction qui acceptera la donnée comme dernier argument.

#### Map

La fonction `map()` prend en paramètre une **projection**, c'est-à-dire une fonction prenant en paramètre un élément de la collection et renvoyant une nouvelle valeur.

Elle renverra une nouvelle collection contenant le résultat de l'application de la projection sur chaque élément du tableau source.

Reprenons notre exemple précédent :

```js
const students = [
  { name: 'Karine Deckow', age: 31 },
  { name: 'Pansy Predovic', age: 23 },
  { name: 'Noe Medhurst', age: 20 },
  { name: 'Vidal Metz', age: 17 },
  { name: 'Cayla Streich', age: 42 }
]
```

Nous voulons récupérer les noms de tous les étudiants :

```js
const getName = student => student.name
const getStudentsNames = R.map(getName)

getStudentsNames(students) // -> 
[
  'Karine Deckow',
  'Pansy Predovic',
  'Noe Medhurst',
  'Vidal Metz',
  'Cayla Streich'
]
```

Si nous combinons cela avec `filter()` vu précédemment, nous pouvons récupérer le nom des étudiants de plus de 25 ans :

```js
const olderThan = age => student => student.age > age
const getName = student => student.name

const getStudentsNames = R.map(getName)
const keepOlderThan25 = R.filter(olderThan(25))

getStudentsNames(keepOlderThan25(students)) // -> 
[
  'Karine Deckow',
  'Cayla Streich'
]
```

✋ Minute ! Ce n'est ni très lisible ni très pratique d'imbriquer les appels de fonctions comme cela. Heureusement, la composition est là pour nous aider :

```js
const getStudentOlderThan25Names = R.pipe(
  keepOlderThan25,
  getStudentsNames,
)
```

Et voilà ! Notre fonction composée n'attend plus que la collection d'étudiants en paramètre, sur laquelle elle va appliquer les deux fonctions successivement.

Ici, on utilise `R.pipe()` qui est semblable à `R.compose()` mais qui appliquera les fonctions de gauche à droite (de haut en bas suivant notre indentation).

Si on retire les variables intermédiaires, on obtient ceci :

```js
const getStudentOlderThan25Names = R.pipe(
  R.filter(olderThan(25)),
  R.map(student => student.name),
)
```

**Rappel** : L'ordre a une importance dans la composition, car si on essaie de filtrer sur l'âge après avoir extrait les prénoms, le prédicat ne fonctionnera pas.

#### Reduce

La fonction `reduce()` prend en paramètre une **fonction binaire** qu'elle applique sur chaque élément, puis renvoie le résultat.

À chaque itération, la fonction est appelée avec l'accumulateur et la valeur courante. L'accumulateur est le résultat de la précédente itération ou la valeur initiale pour la première itération.

```js
const numbers = [2, 5, 8, 4, 11]

numbers.reduce((sum, n) => sum + n, 0)
```

```
  2 + 5    8   4   11
   \ /    /   /   /      
    7  + 8   4   11
     \  /   /   /
      15 + 4   11
       \  /   /
        19 + 11
         \  /
          30             
```

| Accumulateur `sum`    | Valeur courante `n` | Résultat `sum + n`    |
| --------------------- | ------------------- | --------------------- |
| 0 (*valeur initiale*) | 2                   | 2                     |
| 2                     | 5                   | 7                     |
| 7                     | 8                   | 15                    |
| 15                    | 4                   | 19                    |
| 19                    | 11                  | 30 (*résultat final*) |

Reprenons notre exemple :

```js
const students = [
  { name: 'Karine Deckow', age: 31 },
  { name: 'Pansy Predovic', age: 23 },
  { name: 'Noe Medhurst', age: 20 },
  { name: 'Vidal Metz', age: 17 },
  { name: 'Cayla Streich', age: 42 }
]
```

On veut récupérer la somme des âges de tous les étudiants.

De manière impérative, on pourrait faire ceci :

```js
let cumul = 0

for (const student of students) {
  cumul += student.age
}
```

Voici comment on obtient le même résultat avec `reduce()` :

```js
const aggregateStudentAge = (total, student) => total + student.age
const totalStudentsAge = R.reduce(aggregateStudentAge, 0)

totalStudentsAge(students) // -> 133
```

On peut encore améliorer ça, en combinant avec le `map()` de toute à l'heure, on récupère d'abord les âges que l'on additionne ensuite, découplant ainsi la récupération de l'âge de la somme.

```js
const sumStudentAges = R.pipe(
  R.map(student => student.age),
  R.reduce(R.sum, 0)
)
```

Pour la fonction d'addition, on a utilisé `R.sum()` plutôt que l'*arrow function* `(sum, n) => sum + n`.

#### Et pourquoi pas forEach ?

Parce que par définition, `forEach()` ne prend pas en compte le résultat du callback qui lui est passé et ne retourne aucun résultat. Pour être utile, elle doit nécessairement introduire des effets de bord, soit sur des éléments du tableau source, soit sur une variable extérieure ... et vous savez ce que la programmation fonctionnelle pense des effets de bord 😉.

## Dans le prochain épisode ...

Nous aborderons d'autres concepts importants de la programmation fonctionnelle avant de présenter un projet d'exemple illustrant ce que nous avons abordé.

**Restez connectés !** 😉