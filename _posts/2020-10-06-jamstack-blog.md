---
author: Marc
title: Le blog et sa JAMStack
tags: jamstack jekyll blog
---

En guise d'ouverture de ce blog, nous allons détailler sa mise en place avec un concept fort du moment : la **JAMStack**.   
Explications sur son lancement avec : Jekyll & M... Netlify.

## JAMStack, c'est quoi ?

C'est l'acronyme de **J**avaScript **A**PI **M**arkup.   
Contrairement à un CMS plus traditionnel, qui rend des pages dynamiquement depuis une base de données, l'idée est de construire un site web dont les pages sont pré-compilées et donc prêtes à être rendues directement par un serveur.   
Les intérêts sont multiples: 
   
* ***Performance*** : les pages sont prêtes ! Aucun framework vient éxecuter du rendu à la volée.
* ***Scalabilité*** : le contenu peut être héberger sur des CDNs puisqu'il est entièrement statique.
* ***Sécurité*** : Aucune base de données, pas de back office de gestion à mettre à jour régulièrement.

## Notre choix : Jekyll

Il existe un véritable éco-système autour de la JAMStack. On les appelles les **Générateurs de site statique**.
Tous viennent avec leurs concepts mais surtout leurs technologies de prédilection : [Jekyll](https://jekyllrb.com), [Hugo](https://gohugo.io/), [Gatsby](https://www.gatsbyjs.com/), [Next.js](https://nextjs.org/), pour ne citer qu'eux.

![logo jekyll](/assets/images/logos/jekyll.png)

Pour notre besoin relativement simple (maintenir notre site et ce blog), notre choix s'est porté sur Jekyll. 
Ce dernier propose d'écrire ses pages avec un support natif du [Markdown](https://fr.wikipedia.org/wiki/Markdown) (format dont on a l'habitude d'utiliser dans nos projets).   
L'outil vient également avec la gestion de tous les concepts qu'un blog peut contenir : posts, auteurs, categories, tags, etc.
Son utilisation est relativement simple, de par son moteur de templating et ses nombreuses extensions disponibles 
(par exemple notre [flux RSS](/feed.xml) est disponible via un simple ajout du plugin `jekyll-feed`).   
On définit quelques templates, notre CSS, du contenu au format Markdown ou HTML et le tour est joué. A la phase de **build**, Jekyll va transformer notre contenu en un joli site statique prêt à déposer.

## Hébergement : Netlify

Comme évoqué plus haut, une bonne pratique vis à vis d'un site statique est de l'héberger sur un [CDN](https://fr.wikipedia.org/wiki/R%C3%A9seau_de_diffusion_de_contenu). 
S'il y a bien un acteur qui fait émerger ces JAMStack, c'est forcément [Netlify](https://www.netlify.com). 

![logo netlify](/assets/images/logos/netlify.png)

C'est un spécialiste du déploiement et de l'hébergement du contenu statique. 
En quelques clics, on branche son dépôt **Git** (oui, Git fait office de base de données de notre contenu !), éventuellement on configure les DNS, et voilà !
Netlify s'occupe de déployer le site à chaque changement sur la branche **master**, d'activer automatiquement le certificat SSL/TLS via [Let's Encrypt](https://letsencrypt.org/). 
En bonus, Netlify s'occupe de créer une adresse de prévisualisation basée sur les **Pull Request**. Pratique quand on veut voir l'aperçu sans avoir à compiler le projet !

## Y'a plus qu'à...

*... fournir du contenu.*   
Mais aussi et surtout de l'améliorer continuellement. Exploration des extensions qui peuvent nous être utiles, mise en place un CMS pour profiter d'une interface moderne de publication de contenu
, les possibilités sont nombreuses.
En conclusion, une manière efficace, simple et performante pour monter votre site.

## Pour en savoir plus

Quelques liens à disposition :

* [JAMStatic.fr](https://jamstatic.fr/2019/02/07/c-est-quoi-la-jamstack/)
* [Jekyll](https://jekyllrb.com)
* [Intégration Jekyll avec Netlify](https://www.netlify.com/blog/2020/04/02/a-step-by-step-guide-jekyll-4.0-on-netlify/)
