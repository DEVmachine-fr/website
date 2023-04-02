---
author: Sébastien
title: Pourquoi il ne faut pas négliger la maintenance (MCO)
categories: blog
published: false
tags: mco maintenance negligence
---

Après des années d'expériences dans le service numérique et le développement logiciel, je souhaite partager un constat que beaucoup d'entre nous: la plupart des entreprises qui utilise un logiciel développé sur mesure ont tendance à négliger le maintien en conditions operationnelles (ou MCO) de leurs applications.

Cette négligence entraîne de nombreux désagrements qui ne sont pas forcement visibles immédiatement mais dont les conséquences à moyen et long terme peuvent être très importants. 

Je vais détailler dans cet article les avantages/inconvénients d'une bonne MCO uniquement d'un point de vue développement logiciel[^1].

Dans certains cas, ces avantages/inconvénients peuvent également s'appliquer à d'autres domaines que le développement logiciel (matériel/OS/hébergement/....).


## En quoi consiste le maintien en conditions opérationnelles ?

Le maintien en conditions opérationnelles à pour objectif de s'assurer que le logiciel soit toujours disponible.

La disponibilité du logiciel en lui-même peut :
- fonctionnel 
- maintenable
- et sécurisé
 

Il est important de ne négliger aucun de ces 3 points qui sont complémentaires.

La maintenance peut intervenir à plusieurs stades.


### Un logiciel fonctionnel

Le logiciel est destiné à des utilisateurs

### Un logiciel maintenable

Surveillance des frameworks/langages qui sont toujours maintenus. 
Mise à jour vers les dernières versions du ou des langages utilisés.

La maintenance d'un logiciel consiste à surveiller l'obsolescence des composants de ce logiciel.
La notion de composant peut concerner une dépendance

### Un logiciel sécurisé

- Audit de sécurité?
- Surveillance des failles de sécurité (owasp - https://owasp.org/www-project-dependency-check/)

## Quelles sont les obligations d'un maintien en condition opérationnelles ?

- La mise en place des outils (cf plus loin)
- La __volonté__ des décisionnaires d'assurer le MCO.
- Prévoir un budget non fonctionnel.

## Quels sont les avantages d'une maintenance en condition opérationnelles ?

- applications toujours compatibles avec les évolutions des navigateurs
- un temps de maintenance évolutive/corrective optimisé 
- faciliter de trouver des compétences sur le marché

## Comment nous mettons en œuvre le MCO chez DevMachine?

Pour garantir le fonctionnement on met en oeuvre les tests automatisés:
- des tests unitaires.
- des tests d'intégrations

Pour garantir la fraicheur des frameworks utilisés, on utilise des outils de type (TODO).


[^1]: La disponibilité d'un logiciel est bien sur très dépendant de l'infrastructure sur laquelle fonctionne le logiciel. 
  Nous traitons dans cet article que de la partie logicielle.


