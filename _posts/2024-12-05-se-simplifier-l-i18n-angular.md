---
author: Fabien
title: Se simplifier la vie avec Angular et @ngx-translate
categories: ts, angular, js, ngx-translate
---

# Se simplifier l'i18n avec Angular et @ngx-translate

## En utilisant préfixes pour ses clés de traductions

### Introduction

Dans la plupart des cas lorsque l'on développe une application, on est tôt ou tard confronté au besoin de pouvoir facilement la traduire en différentes langues.

C'est l'**internationalisation**, communément abrégé **i18n**.

Une des solutions pour la mettre en œuvre avec Angular est d'utiliser la célèbre bibliothèque `@ngx-translate`.

Avec elle, on définit pour chaque langue un fichier de traduction au format JSON, comme ce fichier `fr.json` :

{% raw %}
```json
{
  "home": {
    "greetings": "Bonjour, {{name}} !"
  }
}
```
{% endraw %}

Et dans nos templates, on utilise le pipe `translate` pour afficher la traduction :

```html
<header>
  <h1>{{ 'home.greetings' | translate: { name: 'Fabien' } }}</h1>
</header>
```

Au fur et à mesure que l'application grossit, on veut davantage structurer notre fichier de traductions. Le niveau d'imbrication commence à augmenter et avec lui, la longueur de nos clés de traductions. Hélas, cela va finir par altérer la lisibilité de nos templates.

```html
<!-- poll-create-form.component.html -->
<form>
  <input type="text"
         id="title"
         [placeholder]="'polls.create.form.title' | translate">

  <select>
    <option>{{ 'polls.create.form.type.single' | translate }}</option>
    <option>{{ 'polls.create.form.type.multiple' | translate }}</option>
    <!-- ... -->
  </select>

</form>
```

On constate qu'en plus d'être longues, ces clés sont redondantes, la première partie `polls.create.form` étant toujours la même pour notre composant.

**Et si on structurait nos traductions par composant ?**

Cela permettrait d'associer à chacun de nos composants un nœud contenant les traductions qui leurs sont propres.

Dans cet article, on va tenter d'apporter une solution simple au problème de la longueur des clés de traductions.

**C'est parti !**

**Attention** : cette solution n'a été testée que pour des applications Angular en mode *standalone*.

### Première proposition

On choisit de définir une constante contenant le préfixe dans la logique métier de notre composant

```ts
@Component({
  standalone: true,
  templateUrl: './poll-create-form.component.ts'
})
export class PollCreateComponent {
    readonly prefix = 'polls.create.form'
}
```

On créé le nœud correspondant à notre composant dans le fichier de traductions :

```json
{
  "polls": {
    "create": {
      "form": {
        "title": "Créer un sondage",
        "type": {
          "single": "Choix simple",
          "multiple": "Choix multiples"
        }
      }
    }
  }
}
```

Et ensuite on ajoute le préfixe à chacune de nos clés de traductions

```html
<form>
  <input type="text"
         id="title"
         [placeholder]="prefix + 'title' | translate">

  <select>
    <option>{{ prefix + 'type.single' | translate }}</option>
    <option>{{ prefix + 'type.multiple' | translate }}</option>
    <!-- ... -->
  </select>
    
</form>
```

Pas mal, mais je pense qu'on peut faire mieux.

L'idéal serait de pouvoir communiquer le préfixe à notre pipe de traduction depuis le composant.

On pourrait passer le préfixe en argument du pipe, mais cela reste redondant. Comment pourrait-on faire en sorte que notre pipe détermine le préfixe en fonction du composant qui l'utilise ?

Et si on utilisait le mécanisme d'injection de dépendances d'Angular ?

### Proposition finale

On s'en sert déjà sans forcément sans rendre compte, mais quand on va appeler notre pipe dans notre composant, c'est bien l'injection de dépendances qui va l'instancier et nous le fournir, en fonction du contexte du composant.

**1ère étape** : on va créer un token d'injection, qui va permettre d'identifier de manière unique la ressource à injecter, ici notre préfixe

Dans le fichier de configuration de l'app `app.config.ts`, on définit notre token :

```ts
export const I18N_PREFIX = new InjectionToken<string>('I18N_NAMESPACE')
```

**2ème étape** : dans le composant, on va créer un **provider** qui va fournir une valeur pour ce token.

```ts
@Component({
  ...
  providers: [ { provide: I18N_PREFIX, useValue: 'polls.create.form' } ]
})
export class PollsCreateFormComponent { ... }
```

**3ème étape** : Dans notre pipe, on va demander à injecter le préfixe en se servant de notre token

```ts
private readonly prefix = inject(I18N_PREFIX, { optional: true })
```

Il est important de préciser `optional: true` car si jamais le composant ne définit pas de provider pour ce token, on veut à tout prix éviter une erreur.

Pour le mécanisme de traduction, on choisit bien évidemment de ne pas réinventer la roue (surtout pas celle-ci 😆) et d'hériter du `TranslatePipe` proposé par `@ngx-translate` .

Voilà ce que ça donne :

```ts
@Pipe({
  name: 'translateNs',
  standalone: true,
  pure: false,
})
export class TranslateNsPipe extends TranslatePipe implements PipeTransform {
  private readonly prefix = inject(I18N_PREFIX, { optional: true })

  override transform(query: string, ...args: unknown[]): any {
    const key = this.namespace ? `${this.namespace}.${query}` : query;
    return super.transform(key, ...args);
  }
}
```

On surcharge la méthode `transform`, et on ajoute le préfixe à la clé s'il existe, puis on appelle la fonction du parent.

Note 1 : Vous aurez peut-être noté le `pure: false` dans le décorateur du pipe ? Je ne rentre pas dans le détail mais étant donné que `TranslatePipe` est impur, il faut que notre pipe le soit aussi. Sans ce paramètre, le pipe ne fonctionnera pas correctement.

Note 2 : J'ai choisi d'utiliser `inject()` et non le constructeur ici car cela m'aurait obligé à injecter aussi les dépendances du parent pour pouvoir appeler son constructeur.

**Voilà, notre pipe est prêt !**

Maintenant il nous reste plus qu'à mettre à jour notre template  :

```html
<form>
  <input type="text"
         id="title"
         [placeholder]="'title' | translateNs">

  <select>
    <option>{{ 'type.single' | translateNs }}</option>
    <option>{{ 'type.multiple' | translateNs }}</option>
    <!-- ... -->
  </select>

  <!-- D'autres champs ... -->
</form>
```

