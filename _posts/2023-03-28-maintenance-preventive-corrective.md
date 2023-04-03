---
author: Sébastien
title: Quels sont les enjeux d'une maintenance applicative ?
categories: blog
tags: mco maintenance préventive corrective budget
---


La maintenance des applications informatiques consiste à assurer la disponibilité du logiciel.
La maintenance peut être effectuée à différents stades de l'application : avant ou après l'apparition d'un problème.

Les dysfonctionnements évoqués dans cet article sont ceux qui n'ont pas été détectés dans la phase de tests/recette de l'application avant sa mise en production. 
Je prends comme hypothèse que l'application a été testée avant sa mise en production.
Même si la recette est bien faite, il est toujours possible qu'un dysfonctionnement intervienne en production.

<!-- TOC -->
  * [En quoi consiste la maintenance ?](#en-quoi-consiste-la-maintenance-)
  * [Prévenir avec la maintenance préventive](#prévenir-avec-la-maintenance-préventive)
    * [Se tenir informé ...](#se-tenir-informé-)
    * [... et prendre la bonne décision](#-et-prendre-la-bonne-décision)
    * [Quel est l'intérêt d'une maintenance préventive ?](#quel-est-lintérêt-d--une-maintenance-préventive-)
  * [Guérir avec la maintenance corrective](#guérir-avec-la-maintenance-corrective)
    * [Quand sait-on qu'il y a un problème ?](#quand-sait-on-quil-y-a-un-problème-)
  * [Ce qu'il faut en retenir](#ce-quil-faut-en-retenir)
    * [L'absence de prévention, c'est accumuler de la dette...](#labsence-de-prévention-cest-accumuler-de-la-dette)
    * [...Qu'il faudra bien payer un jour](#quil-faudra-bien-payer-un-jour)
<!-- TOC -->

## En quoi consiste la maintenance ?

La maintenance consiste à modifier une partie du code du logiciel pour en corriger les dysfonctionnements ou en améliorer son efficacité.
Cette partie du code peut être dans une dépendance (ou bibliothèque) externe.
Cela peut également venir du langage d'exécution en lui-même.
Pour regrouper ces 3 notions je parlerais ici de _composant_.

Il existe plusieurs types de maintenance que nous allons voir dans la suite de cet article.
Chaque type de maintenance à son lot d'avantages et d'inconvénients.

Quel que soit le type de maintenance, la plupart du temps, les actions effectuées sont les mêmes.
Cela peut concerner le remplacement d'une version d'une ou plusieurs dépendances par :
- une mise à jour de la dépendance qui corrige des problèmes que d'autres ont rencontrés
- un remplacement de la dépendance par une autre dépendance plus efficace et/ou toujours maintenue.
- une modification ou une réécriture du code

Cela peut concerner du code spécifique à l'application qui est lié à une mauvaise pratique ou un mauvais usage.
Par exemple, l'absence de contrôle des données d'entrée d'un webservice peut entrainer une alteration non désirée des données dans la base de données.

_Le cas le plus courant d'un manque de contrôle est l'élévation de privilège._ [1] 
## Prévenir avec la maintenance préventive

Comme son nom l'indique, la maintenance préventive intervient **_avant_** qu'un problème ne surgisse.

Il s'agit d'anticiper d'éventuels dysfonctionnements en remplaçant certains composants du logiciel.

### Se tenir informé ...

Pour anticiper d'éventuels problèmes, il est important de se tenir informé.
Pour cela, il est important de faire de la veille. 
Cette veille peut être manuelle par de lecture de sites spécialisés.
On peut également s'abonner à différentes sources d'informations afin d'être notifié (par mail, flux RSS, ...) lorsqu'un problème est rencontré.

<img alt="Configuration des notifications sur un projet github" height="300" src="/assets/images/maintenance/github_notifications.png" title="Configuration des notifications sur un projet github"/>

### ... et prendre la bonne décision

Lorsque nous sommes informés d'un dysfonctionnement d'un composant du logiciel, il ne faut pas forcément se précipiter.
En effet, une mise à jour de composant peux corriger un problème mais peut également entrainer un autre dysfonctionnement.

Il est donc important d'évaluer les risques avant de faire le changement.

De plus, selon le type de mise à jour, les impacts sur le code existant peut être plus ou moins important.
Il faut donc estimer les impacts de la mise à jour et le temps à passer pour faire cette mise à jour.

### Quel est l'intérêt d'une maintenance préventive ?

Il est important de consacrer du temps pour la maintenance préventive. 
Du temps pour faire la veille et évaluer les risques et du temps pour faire les modifications nécessaires.

Le temps passé à prévenir les problèmes permet d'économiser le temps lorsque les problèmes arriveront.
Car lorsque les problèmes arrivent, les conséquences peuvent être importantes.

Pour faire une analogie : la maintenance préventive, c'est un peu comme le monde automobile. 
En effet, si l'entretien de votre voiture est fait régulièrement vous éviterez le plus possible les gros problèmes et les conséquences qui en découlent.

## Guérir avec la maintenance corrective

La maintenance corrective intervient **_après_** qu'un problème soit détecté.

Encore faut-il que le problème soit détecté.

### Quand sait-on qu'il y a un problème ?

Il peut y avoir plusieurs types de problème. Les problèmes visibles et les problèmes invisibles.
La majorité des problèmes sont détectés par une action directe. 
Cela peut être une action utilisateur ou un appel de webservice.
Dans ce cas la detection est assez rapide, voir immédiate.

Mais il peut aussi y avoir des actions plus discrete qui ne permettent pas de détecter rapidement le dysfonctionnement.
Il peut s'agir d'un batch ou d'une action automatique qui met à jour la base de données mais avec un mauvais comportement.
Il peut s'agir d'une suppression de données (totale ou partielle) ou d'une modification de données non désirée.

Selon la nature du dysfonctionnement, il peut y avoir un certain délai entre le dysfonctionnement et sa détection.
Il peut y avoir un délai encore plus grand entre le moment où le problème est détecté et sa correction.

Une fois le dysfonctionnement détecté, il faut que l'information circule afin qu'elle soit transmise à l'équipe de développement
Cela peut passer par plusieurs mécanismes :
- un outil de gestion de ticket (JIRA, Redmine, ...)
- le gestionnaire de ticket du projet (github, gitlab)
- un email
- ... 


## Ce qu'il faut en retenir

La majorité du temps, pour des décideurs, la maintenance informatique n'est pas un sujet prioritaire.
C'est un sujet difficilement quantifiable.

Il est donc plus facile de prévoir une enveloppe budgetaire pour gérer les problèmes quand ils arriveront (maintenance corrective) que de prévoir un budget pour prévenir les éventuels futurs problèmes (maintenance préventive).
C'est malheureusement une vision à court terme.

L'absence de maintenance préventive entraine des conséquences techniques et financières à moyen et long terme.

### L'absence de prévention, c'est accumuler de la dette...

A moyen terme, si on ne met pas à jour le code ou les dépendances régulièrement, le projet va accumuler une dette technique.
Avec l'accumulation de la dette technique, il faut prendre en compte le cout du maintien des compétences sur le projet.
Ce cout n'est souvent pas pris en compte dans le budget de maintenance des applications.

Ex: Aujourd'hui, maintenir un projet en JSF (pour ceux qui connaissent :) ) coutera plus cher à maintenir qu'un projet en SpringBoot angular. 
Car il faut trouver des compétences capables d'intervenir sur un projet en JSF. Ces compétences sont rares sur le marché. 

L'évolution des frameworks modernes permet, de plus en plus, de s'abstraire des couches techniques pour se concentrer sur le métier.
Ils permettent donc de gagner du temps lors du développement des fonctionnalités.
Ce gain de temps n'est pas réalisable pour des projets qui ne sont pas maintenus régulièrement.

Ex: Implémenter des requêtes en base de données réalisées avec l'API Criteria prendra plus de temps qu'avec un framework de type spring data.
En effet, spring data permet (dans la grande majorité des cas) de ne pas implementer les requêtes mais seulement en définir la signature. 
C'est donc un gain en productivité pour les futures évolutions.

### ...Qu'il faudra bien payer un jour

La maintenance corrective est une obligation puisqu'il s'agit de traiter les problèmes qui sont présent.
Mais ne faire que de la maintenance corrective n'est pas suffisant pour garantir une longévité efficace à une application.

Il est important de faire aussi de la maintenance préventive afin de réduire les risques d'avoir des problèmes en production.

L'absence de maintenance régulière, va entrainer des couts indirects (de maintien des compétences, de temps de correction, ...).
Dans le calcul de la maintenance, ces couts indirects sont rarement pris en compte, par les décideurs, dans le cout global d'une application.

La limite extreme est, qu'au bout d'un moment, la décision soit prise de refaire complétement l'application car elle n'est plus maintenable ou que le cout de maintenance soit trop élevé. 
Cette décision entraine souvent beaucoup de frilosité car il faut engager beaucoup d'argent pour cette refonte.

## Notes

1. [1] - [https://fr.wikipedia.org/wiki/%C3%89l%C3%A9vation_des_privil%C3%A8ges](https://fr.wikipedia.org/wiki/%C3%89l%C3%A9vation_des_privil%C3%A8ges)
