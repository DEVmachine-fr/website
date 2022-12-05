---
author: Fabien
title: Introduction à la programmation fonctionnelle en JavaScript, partie 2
categories: js fp functional programming ramda node
---


Dans la suite de cette série d'articles, nous continuerons d'aborder les concepts importants de la programmation fonctionnelle JavaScript.

# Introduction à la programmation fonctionnelle en JS, partie II <!-- omit in toc -->

- [Précédemment ...](#précédemment-)
- [Les concepts, la suite](#les-concepts-la-suite)
  - [Les structures algébriques](#les-structures-algébriques)
    - [Les foncteurs](#les-foncteurs)
    - [Les monades](#les-monades)
  - [Les types algébriques](#les-types-algébriques)
    - [Le type `Maybe`](#le-type-maybe)
    - [Le type `Either`](#le-type-either)
    - [Le type `Future` de la bibliothèque *fluture-js*](#le-type-future-de-la-bibliothèque-fluture-js)
- [Dans le prochain épisode ...](#dans-le-prochain-épisode-)

## Précédemment ...

[Dans la première partie de cet article](https://www.devmachine.fr/js/fp/functional/programming/ramda/node/2022/10/11/introduction-programmation-fonctionnelle_partie1.html), nous avons introduit ce qu'était la programmation fonctionnelle et expliquer ses grands principes, puis nous avons abordé certains de ses concepts, comme la composition de fonctions et les fonctions d'ordre supérieur.

Cette semaine, nous continuons à aborder d'autres concepts importants de la programmation fonctionnelle : ***les structures et les types algébriques***.

## Les concepts, la suite

### Les structures algébriques

En programmation fonctionnelle, les structures algébriques sont des outils permettant de résoudre des problèmes particuliers, de la même manière que le font les *designs patterns* en programmation orientée objet. 
Mais contrairement à ces derniers, leurs bases sont définies par les mathématiques et non par la seule observation : elles sont définies plus formellement et possèdent leurs lois propres.

**En pratique, on peut considérer les structures algébriques comme des types conteneurs de données proposant des opérations permettant de la traiter en fonction du contexte.**

Il existe en JavaScript une spécification pour les structures algébriques appelée *Fantasy Land*. Pour chacune des structures, la spécification liste les méthodes qu'un objet doit proposer. Ces méthodes ont chacune une signature et une série de lois auxquelles elles doivent obéir.

Si ce concept peut sembler abstrait et sa théorie complexe, les exemples ci-après montreront qu'il est plus simple que ce qu'il laisse croire et que bon nombre d'entre nous ont déjà utilisé partiellement ces outils sans forcément s'en rendre compte.

#### Les foncteurs

Commençons par la structure la plus simple, les **foncteurs** (*functor*).

```haskell
map :: Functor f => f a ~> (a -> b) -> f b
```

On appelle cette écriture la *notation de Hindley-Milner*. Ici, elle décrit 3 choses :

- Un foncteur `f` doit proposer une méthode `map`
- `map` prend en paramètre une fonction : celle-ci attend une donnée de type `a` et renvoie une donnée de type `b`
- Un foncteur contenant des éléments de type `a`, noté `f a` sur laquelle on appelle `map` avec une fonction `a -> b` renvoie le même type de foncteur, mais contenant des éléments de type `b`, noté `f b`.

Le type `Array` en JavaScript est un foncteur, servons-nous en comme un exemple pour vérifier ce que nous venons de décrire :

```js
const n = [1, 2, 3, 4] // Array<number>
const fn = n => `${n}` // number -> string

n.map(fn) // => Array<string> = ['1', '2', '3', '4']
```

- `Array` propose bien une méthode `map`
- `map` prend ici la fonction `fn` transformant des nombres en chaînes de caractères (`number -> string`)
- `map` retourne bien le même type de foncteur (ici `Array`) mais contenant des éléments d'un type différent (`f a` devient `f b`).

Pour résumer, la fonction `map` permet donc d'appliquer une fonction sur une valeur qui est encapsulée dans un conteneur, et de ré-encapsuler le résultat dans un autre conteneur.

Enfin, un foncteur suit les deux lois suivantes :

- **la loi d'identité** : Si `u` est un foncteur, appeler `map` avec la fonction d'identité est équivalent à `u` :
  
  ```js
  u.map(x => x) ≡ u
  ```

- **la loi de composition** : Si `u` est un foncteur, appeler `map` avec la composée `f ∘ g` est équivalent à appeler successivement map avec la fonction `g` puis avec `f` :
  
  ```js
   u.map(f(g(x))) ≡ u.map(g).map(f)
  ```

**Notes** :

- La **fonction d'identité** (*Identity*) est une fonction renvoyant l'argument qu'elle reçoit

- Le symbole `≡` représente une équivalence en mathématique

#### Les monades

Voyons maintenant en quoi consiste une monade :

```haskell
chain :: Monad m => m a ~> (a -> m b) -> m b
```

La notation de *Hindley-Milner* nous décrit 3 choses :

- Une monade `m` doit proposer une méthode `chain`
- `chain` prend en paramètre une fonction : celle-ci attend une donnée de type `a` et renvoie une monade contenant une donnée de type `b` (`m b`).
- Une monade contenant des éléments de type `a`, noté `m a` sur laquelle on appelle `chain` avec une fonction `a -> m b` renvoie le même type de monade, mais contenant des éléments de type `b`, contenue par la monade `m b`.

Pour résumer, la fonction `chain` permet d'appliquer une fonction sur une valeur qui est encapsulée dans un conteneur, renvoyant une valeur elle-même encapsulée dans un conteneur, et de ré-encapsuler ce résultat en sortie.

**Note** : D'après *Fantasy Land*, la structure algébrique `Monad` déclare d'autres opérations et lois, mais je n'ai détaillé ici que la partie qui nous intéresse pour la suite.

### Les types algébriques

#### Le type `Maybe`

`Maybe` est à la fois un **foncteur** et une **monade** qui va nous permettre de gérer l'éventualité d'une opération retournant une valeur nulle (`null` et `undefined` en JavaScript).

```haskell
data Maybe a = Nothing | Just a
```

Le type `Maybe` définit deux contextes différents :

- soit il n'y a aucune valeur : `Nothing`

- soit il y en a une : `Just(<value>)`

`Maybe` étant un foncteur, on peut appeler `map` pour tenter d'appliquer un traitement sur la valeur contenue dans le contexte.

Voici un exemple dans lequel nous utiliserons la bibliothèque JavaScript *sanctuary* et son implémentation de `Maybe` :

```js
import S from 'sanctuary'

const maybeIntA = S.Just(20)
const maybeIntB = S.Nothing

const double = S.mult(2)
```

Ici on veut doubler la valeur à l'intérieur de chaque `Maybe` :

```js
maybeIntA.map(double) // --> Just(40)
maybeIntB.map(double) // --> Nothing
```

On voit que grâce à ce mécanisme de foncteur, on peut appliquer le traitement sur un conteneur avec un nombre de la même manière que sur un conteneur vide. Dans le cas de `Nothing`, la fonction `map` se contente de retourner `Nothing` sans exécuter le traitement.

On peut ainsi chaîner plusieurs traitements, le moindre `Nothing` court-circuitera la chaîne sans provoquer d'erreur.

Maintenant, voyons un autre exemple dans lequel on a une fonction `half` qui renvoie la moitié d'un nombre pair, ou rien si le nombre est impair. Rappelons que `Maybe` est aussi une **monade**, et qu'elle implémente donc l'opération `chain`. Étant donné que `half` prend un nombre pour renvoyer un `Maybe` contenant un nombre, c'est cette opération que nous allons devoir utiliser à la place de `map`.

Rappelons la notation de *Hindley-Milner* pour l'opération `chain` des monades :

```haskell
chain :: Monad m => m a ~> (a -> m b) -> m b
```

Voici ce que cela donne :

```js
const half = n => (n % 2 !== 0) ? S.Nothing : S.Just(n / 2) 

const compute = S.pipe([
  S.chain(half), // --> Just(10)
  S.chain(half), // --> Just(5)
  S.chain(half), // --> Nothing
  S.chain(half), // --> Nothing
])

compute(S.Just(20))
```

En chaînant les appels à `half` via l'opérateur `chain`, on obtient la moitié de 20, puis de 10, et on voit qu'à partir de 5, `map` renvoie `Nothing`, et le fera peu importe le nombre d'appels suivant à `half`.

#### Le type `Either`

`Either` va nous permettre de gérer les erreurs dans un traitement ou une chaîne de traitement sans utiliser les exceptions.

```haskell
data Either l r = Left l | Right r
```

Le type `Either` peut contenir 2 contextes différents :

- soit une valeur gauche : `Left(<value>)`

- soit une valeur droite : `Right(<value>)`

La valeur gauche sera utilisée pour décrire une erreur, généralement un message d'erreur sous forme de `string`.

La valeur droite contiendra le résultat d'un traitement.

D'une manière un peu similaire à `Maybe` avec `Nothing`, une valeur de type `Left` va court-circuiter le traitement et être simplement renvoyée à travers toute la chaîne.

Voici un exemple très semblable à celui exposé ci-dessus pour `Maybe` :

```js
const half = (n => n % 2 !== 0) ? S.Left(`${n} is not an even number`) : S.Right(n / 2) 

const compute = S.pipe([
  S.chain(half), // --> Right(10)
  S.chain(half), // --> Right(5)
  S.chain(half), // --> Left('5 is not an even number')
  S.chain(half), // --> Left('5 is not an even number')
])

compute(S.Right(20))
```

Encore une fois, on s'aperçoit que `Either` et `Maybe` sont assez proches :

- le contexte `Left` correspond à `Nothing`, à la différence qu'il contient une valeur

- le contexte `Right` correspond à `Just`

D'ailleurs, la bibliothèque *sanctuary* propose des fonctions utilitaires permettant de passer aisément d'un type à l'autre :

```js
S.maybeToEither ('Expecting a value') (S.Nothing)
// --> Left ('Expecting a value')

S.maybeToEither ('Expecting a value') (S.Just (42))
// --> Right (42)

S.eitherToMaybe (S.Left ('Cannot divide by zero'))
// --> Nothing

S.eitherToMaybe (S.Right (42))
// --> Just (42)
```

#### Le type `Future` de la bibliothèque *fluture-js*

Pour gérer l'asynchronisme, on utilise généralement les `Promises`. Cet objet pourrait s'apparenter en programmation fonctionnelle à un *conteneur de données* avec les deux *contextes* suivants :

- **Resolved** : la promesse est résolue, le traitement asynchrone est terminé et peut éventuellement contenir un résultat

- **Rejected** : la promesse est rejetée, le traitement a échoué et peut éventuellement contenir une valeur décrivant la raison de cet échec (pas nécessairement un objet ni une exception)

Mais il y a un problème : sa méthode `.then()` permet d'effectuer trois opérations distinctes :

1. Appliquer une fonction sur la valeur asynchrone :
   
   ```js
   const getPrice = Promise.resolve(10) // Promise(10)
   const getPriceVAT = getPrice().then(p => p * 1.2) // Promise(12)
   ```

2. Appliquer une fonction asynchrone sur la valeur asynchrone :
   
   Si le résultat de la fonction passée à `then` est une `Promise`, ces deux promesses seront automatiquement chaînées.
   
   ```js
   const getPriceInUSD = Promise.resolve(10) 
   const getUSDToEURExchangeRate = Promise.resolve(0.97)
   const getPriceInEUR = priceInUSD => priceInUSD 
     .then(price => getUSDToEURExchangeRate()
       .then(rate => rate * price)
     )
   
   getPriceInEUR(getPriceInUSD()) // -> Promise(9.7)
   ```
   
   Dans cet exemple, lorsque la promesse renvoyée par `getPriceInUSD` est résolue, son résultat est passé à `getUSDToEURExchangeRate` qui renvoie elle aussi une promesse : la résolution de celle-ci déclenchera la résolution de la promesse finale, avec le résultat attendu.

3. Réagir à un valeur asynchrone :
   
   Généralement lorsqu'on ne retourne rien dans la fonction passé au `then`, mais qu'on veut afficher le résultat, par exemple dans la console :
   
   ```js
   const getArticlePrice = id => {...} // number -> Promise<number>
   getArticlePrice(1)
     .then(price => console.log(price))
     .catch(err => console.error(err))
   ```

Le type `Future` de la bibliothèque `fluture-js` permet de faire la même chose qu'avec une `Promise`, mais il sépare ces opérations en trois méthodes distinctes, et est conforme à la spécification **Fantasy-land**, ce qui le rend parfaitement compatible avec la bibliothèque *sanctuary* vue plus haut.

```haskell
data Future a b = Reject a | Resolve b
```

Si l'on reprend les trois cas de figures vus plus haut, voici comment ils sont respectivement traités grâce au type `Future` :

1. Via la méthode `map` :
   
   ```js
   const getPrice = { ... } // Resolve(10)
   const getPriceVAT = F.map(price => price * 1.2)
   
   getPriveVAT(getPrice()) // Resolve(12)
   ```

2. Via la méthode `chain` :
   
   ```js
   const getPriceInUSD = { ... } // Resolve(10)
   const getUSDToEURExchangeRate = _ => { ... } // Resolve(0.97)
   
   const getPriceInEUR = F.chain(price => 
     F.map(rate => rate * price)(getUSDToEURExchangeRate())
   )
   
   getPriceInEUR(getPriceInUSD()) -> // Resolve(9.7) 
   ```

3. Via la méthode `fork` :
   
   ```js
   const getArticlePrice = id => {...} // number -> Future string number
   
   F.fork (console.error) (console.log) (getArticlePrice(1))
   // > 45.00
   F.fork (console.error) (console.log) (getArticlePrice(-1))
   // > 'No article with id -1 exists'
   ```

Il y a plusieurs méthodes disponibles pour créer des *futures* :

1. Via le constructeur `Future`

2. À partir d'une `Promise` grâce à la fonction `encaseP`

3. À partir d'un *callback* **Node.js** grâce à la fonction `node`

Il existe également des *shorthands* pour créer des futures, comme `resolve`, `reject`, `resolveAfter`, etc.

Je ne peux que vous conseiller leur excellente documentation pour approfondir les possibilités offertes par cette bibliothèque : [fluture-js/Fluture](https://github.com/fluture-js/Fluture).

## Dans le prochain épisode ...

Nous verrons comment tous les concepts abordés jusqu'à présent peuvent être appliqués au travers d'un exemple d'API Web.

**Restez connectés !** 😉
