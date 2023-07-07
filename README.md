# Site Web de DEVmachine

Ceci est le code source du site web de [DEVmachine](https://www.devmachine.fr).

## Pré-requis

Avoir Ruby d'installé sur son environnement. ([https://www.ruby-lang.org/](https://www.ruby-lang.org/))

## Installation

Le site est basé sur le générateur de site statiques [Jekyll](https://jekyllrb.com/).   
Il est donc nécessaire d'installer Jekyll au préalable.

    gem install bundler jekyll
    

## Utilisation

Pour installer les dépendances :
```shell
    bundle install
```

Pour compiler le site il suffit d'exécuter la commande:
```shell
    jekyll build
```

Un dossier `_site` est alors créé et contient le site statique généré.

Il est possible de travailler avec du Live Reload en exécutant la commande
```shell
    jekyll serve
```

ou

```shell
    bundle exec jekyll serve
```

Un serveur démarre sur le port 4000, et le site est visible sur l'adresse : http://127.0.0.1:4000

## Via docker

Au préalable, vérifier que les dossiers `.jekyll-cache` et `_site` sont disponibles à la racine du répertoire.

```shell
docker run --rm --volume="$PWD:/srv/jekyll" -p 4000:4000 -it jekyll/builder:4.0 jekyll serve --trace --drafts --watch
```
