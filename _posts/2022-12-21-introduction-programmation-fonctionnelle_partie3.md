---
author: Fabien
title: Introduction à la programmation fonctionnelle en JavaScript, partie 3
categories: js fp functional programming ramda node
---

Dans la dernière partie de cette série d'article, nous allons enfin pouvoir illustrer tous les concepts abordés précédemment au travers d'un exemple simple d'API.

- [Précédemment ...](#précédemment-)
- [Un exemple simple d'API pour illustrer](#un-exemple-simple-dapi-pour-illustrer)
  - [Présentation rapide de l'API](#présentation-rapide-de-lapi)
  - [Déclaration de la route d'import](#déclaration-de-la-route-dimport)
    - [Version impérative](#version-impérative)
    - [Version fonctionnelle](#version-fonctionnelle)
  - [Parsing du CSV](#parsing-du-csv)
    - [Version impérative](#version-impérative-1)
    - [Version fonctionnelle](#version-fonctionnelle-1)
  - [Connexion à la base de données](#connexion-à-la-base-de-données)
    - [Version impérative](#version-impérative-2)
    - [Version fonctionnelle](#version-fonctionnelle-2)
  - [Accès aux sources de l'exemple](#accès-aux-sources-de-lexemple)
- [Conclusion](#conclusion)

# Introduction à la programmation fonctionnelle en JS, partie III <!-- omit in toc -->

## Précédemment ...

Dans la [première](https://www.devmachine.fr/js/fp/functional/programming/ramda/node/2022/10/11/introduction-programmation-fonctionnelle_partie1.html) et la [seconde partie](https://www.devmachine.fr/js/fp/functional/programming/ramda/node/2022/12/09/introduction-programmation-fonctionnelle_partie2.html) de cet article, nous avons pu présenter et aborder une grande partie des concepts de la programmation fonctionnelle.

Pour terminer cet article, il est temps pour moi de vous montrer comment ces concepts peuvent être appliqués à travers un exemple simple d'API.

## Un exemple simple d'API pour illustrer

Je vais donc vous présenter un petit exemple d'API basique écrite avec **Node.js** et le framework **Express**. Je vais d'abord expliquer son fonctionnement puis montrer des parties du programme écrites de manière impérative : cela me permettra ensuite de vous expliquer comment j'ai réécrit ces portions de code de manière fonctionnelle, pour illustrer au mieux les concepts expliqués dans cet article.

### Présentation rapide de l'API

Cette API de démonstration est volontairement simple et ne propose qu'une seule route,  `POST /import`, qui permet d'envoyer un fichier CSV contenant des informations sur différents modèles de voitures.

Voici un exemple de fichier de données que l'API peut consommer :

| brand | model       | year | energy | engine              | transmission | gearbox | power |
| ----- | ----------- | ---- | ------ | ------------------- | ------------ | ------- | ----- |
| Tesla | Model S P85 | 2012 | E      | electric rear-motor | R            | E       | 500   |

### Déclaration de la route d'import

#### Version impérative

Voici le code qui déclare la route en version impérative :

```js
app.post('/import', uploads.single('content'), async (req, res, next) => {
  try {
    const { file } = req

    // throws an error
    checkFile(file)

    // parse CSV
    const lines = await parseCSVFile(file)
    const proceededLines = []

    // process each lines
    for (const line of lines) {
      const newLine = await processLine(line)
      proceededLines.push(newLine)
    }

    // IO write
    await saveLinesToDb(db, proceededLines)

    // Write response to the client
    res.status(200).json(proceededLines)
  } catch (err) {
    next(err)
  }
})
```

On peut voir dans cet extrait de code que la route va effectuer différents traitements :

- Import du fichier (via une bibliothèque externe, les informations sur le fichier sont récupérées dans le variable `file`).

- Vérification de la présence du fichier et de son extension ( `checkFile()`).

- &laquo;*Parser*&raquo; le texte du fichier CSV en un objet (`parseCSVFile`)

- Traiter/transformer les valeurs de certaines colonnes, notamment celles contenant des codes (`processLines`).

- Enregistrer les données sous forme de document dans une base **MongoDb** (`saveLinesToDb`).

- Renvoyer ces données au client

#### Version fonctionnelle

```js
app.post('/import', uploads.single('content'), (req, res) => { 
  S.either 
      ( writeHttpErrorResponse(res) )               // ❌ Error case
      ( R.partialRight(importCSVOperation, [res]))  // ✔️ Success case (String)
    ( tryGetFilepath(req) ) // -> Either Error | String
})
```

La structure du code est totalement différente ici : on utilise le mécanisme fourni par le type algébrique `Either` que l'on a abordé plus haut : la fonction `tryGetFilePath` va prendre en paramètre l'objet de la requête `req` et tenter de renvoyer le chemin d'accès vers le fichier importé.

Conformément à ce mécanisme, ce conteneur peut renfermer deux contextes différents : une **valeur gauche** contenant la description de l'erreur ou une **valeur droite** contenant le chemin du fichier importé.

Ici, on utilise la fonction `either` de la bibliothèque *Sanctuary* pour traiter le contexte renvoyé par `tryGetFilepath` :

- Renvoyer le message d'erreur au client si on a une **valeur gauche**

- Appeler `importCSVOperation` avec le chemin du fichier et l'objet `req` si on a une **valeur droite**

On remarque rapidement l'écriture particulière de `either` :

```js
S.either (traitementErreur) (traitementValeur) (either) 
```

Vous aurez sans doute compris qu'il s'agit d'une fonction *currifiée*. Si `either` vaut `Right(42)`, alors la fonction `traitementValeur` sera appelée avec l'argument `42`. Sinon, si elle renvoie `Left('Bad value')`, c'est la fonction `traitementErreur` qui sera appelée avec la chaîne `'Bad value'`.

La fonction `importCSVOperation` reprend ce qui était fait de manière impérative dans le *middleware* de la route :

```js
const importCSVOperation = (filepath, res) => {
  // Process each lines
  const processLines = R.map(processLine)

  // Write error response to the client and log it
  const errorLogAndWriteOnResponse = R.pipe(
    R.tap(console.error),
    writeErrorResponse(res)
  )

  parseCSVFile(filepath)
    .pipe(F.map ( processLines ))    
    .pipe(F.chain ( saveLines(db) ))
    .pipe(F.fork 
      ( errorLogAndWriteOnResponse  )  // ❌ Error case
      ( writeJSONResponse(res, 200) )  // ✔️ Success case 
    )
}
```

On appelle `parseCSVFile()` qui renvoie une `Future` contenant un tableau d'objet correspondant aux lignes du fichier CSV importé.

Grâce à la méthode `.pipe()`, on créé une pipeline qui va chaîner les traitements successifs et les appliquer au résultat du CSV. Ensuite, la fonction `fork()` de la bibliothèque *fluture* nous permet de terminer cette chaîne de traitement en définissant quelle fonction appeler pour traiter le résultat ou une éventuelle erreur, sur le même modèle que la fonction `S.either()` vue plus haut. 

D'ailleurs, elle a exactement la même signature :

```js
F.fork(traitementErreur)(traitementResultat)(future)
```

C'est parce qu'on l'utilise en combinaison de `F.pipe()` ici que l'on n'a pas besoin de préciser le troisième argument, qui est la valeur renvoyée par le pipeline à la fin de l'exécution des traitements.

### Parsing du CSV

Dans les deux cas, on s'appuie sur la bibliothèque *csv-parse*.

#### Version impérative

```js
export async function parseCSVFile(file) {
  const csvParser = csv({ separator: ',' })
  const parsedLines = []

  const { path } = file
  const parseStream = createReadStream(`./${path}`).pipe(csvParser)

  for await (const data of parseStream) {
    parsedLines.push(data)
  }

  return parsedLines
}
```

Ce code reste classique : on instancie le *parser*, puis on créé un **Readable** pour la lecture du fichier grâce à `fs.createReadStream()`. Notez qu'on utilise la construction `for await` qui permet d'itérer sur le stream, car chaque **Readable** fournit un **AsyncIterator**.

On utilise un tableau pour stocker les données émises par le stream.

#### Version fonctionnelle

```js
import * as Fn from 'fluture-node'

const relativePath = path => `./${path}`
const pipeCSVParser = stream => stream.pipe(csv({ separator: ',' }))

export const parseCSVFile =
  R.pipe(
    relativePath,      
    createReadStream,
    pipeCSVParser,
    Fn.buffer,
  )
```

On utilise la composition pour créer notre fonction qui reçoit en paramètre le chemin du CSV :

1. `relativePath` ajoute la sous-chaîne `./` au chemin du fichier

2. `createReadStream` reçoit le chemin relatif et renvoie un **Readable** pour lire le fichier

3. `pipeCSVParser` transforme le stream lisant le fichier pour renvoyer les lignes *parsées*

4. `Fn.buffer` réduit le stream et le transforme en une Future qui contient un tableau de valeurs émises (ici `object[]`).

**Note** : On utilise ici la bibliothèque *fluture-node* qui ajoute des fonctions utilitaires pour l'utilisation de *fluture.js* dans un environnement **Node.js**. La fonction `buffer` nous permet justement de reproduire ce que fait le `for await` dans la version impérative.

### Connexion à la base de données

Pour des raisons de simplicité, on passe par une connexion à **MongoDb** via le driver **Node.js**.

#### Version impérative

```js
export async function getDatabase(mongoUrl) {
  try {
    const client = new MongoClient(mongoUrl);
    await client.connect()
    console.log(`✔️  MongoDb connection to '${mongoUrl}' OK`)

    return client.db()
  } catch (err) {
    console.error(`❌  Unable to connect to MongoDb at url '${mongoUrl}'`)
  }
}
```

Rien d'inhabituel ici, on instancie `MongoClient`, on se connecte, puis on récupère l'instance de la base de données via `db()` .

**Note** : on ne transmet pas le nom de la base de données ici car on l'a déjà renseigné dans l'URL de connexion.

#### Version fonctionnelle

```js
export const getDatabase = mongoUrl =>
  F.go(function* () {
    const client = new MongoClient(mongoUrl)
    yield F.encaseP(mongoConnect)(client)
    return mongoGetDb(client)
  })
    .pipe(F.bimap
      ( R.tap( consoleErr(`❌  Unable to connect to MongoDb at url '${mongoUrl}'`) ))
      ( R.tap( consoleLog(`✔️  MongoDb connection to '${mongoUrl}' OK`) ))
    )
```

On utilise ici la fonction `go` de *fluture.js* ([documentation](https://github.com/fluture-js/Fluture#go)) : elle prend en paramètre une [fonction génératrice](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/function*) qui va émettre des instances de `Future` via le mot-clé `yield`, ce qui va nous permettre de grouper plusieurs opérations asynchrones dans une seule `Future`.

La valeur retournée dans cette fonction correspondra à celle encapsulée par la `Future` que va nous retourner `go()`.

Ce concept reprend le principe des *Promises coroutines*, dont certaines bibliothèques fournissent une implémentation (comme [Bluebird](http://bluebirdjs.com/docs/api/promise.coroutine.html)).

### Accès aux sources de l'exemple

Le code source de l'API servant de démonstration est accessible sur mon dépôt Github [ici](https://github.com/fabien33700/intro-fp-in-js-api).

La branche `main` correspond à la version impérative tandis que `fp` correspond à la version fonctionnelle.

J'ai aussi regroupé les différents articles qui m'ont permis d'appréhender les concepts abordés dans l'article dans cette [bibliographie](https://github.com/fabien33700/intro-fp-in-js-api/blob/fp/BIBLIOGRAPHY.md).

## Conclusion

La programmation fonctionnelle est un paradigme que j'ai trouvé très intéressant : c'est rafraîchissant de voir comment elle aborde différemment les problèmes et y trouve ses propres solutions. De prime abord, elle m'a paru plus complexe et moins accessible, mais cela s'explique en partie par le fait que la majorité d'entre nous sommes davantage habitués à la programmation impérative et à la POO.

Bien qu'imposant une courbe d'apprentissage un peu abrupte et un nombre important de contraintes, la programmation fonctionnelle apporte aussi son lot d'avantages :

- **une meilleure testabilité** : les fonctions pures sont déterministes, ne dépendent d'aucun état extérieur, on peut donc facilement les tester sans avoir recours à des frameworks de mock

- **une meilleure réutilisabilité** : il est possible de découper le comportement en fonctions très petites que l'on peut composer

- **une meilleure lisibilité** : le découpage en fonction permet de mettre des noms explicites sur de petits traitements, et la composition permet de conjuguer aisément ces comportements, rendant l'ensemble plus lisible.

En tant que néophyte de la programmation fonctionnelle, cela me paraît encore compliqué d'envisager de développer un projet de manière 100% fonctionnelle. Toutefois, ce paradigme propose des solutions intéressantes permettant d'adresser des problèmes courants en programmation orientée objet comme la mutation d'objets, ce qui permet d'améliorer la qualité du code et de réduire beaucoup de bugs.
