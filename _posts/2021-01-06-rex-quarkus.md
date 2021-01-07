---
author: Julien
title: Retour d'expérience sur Quarkus
categories: rex quarkus java
---

Après quelques mois en production, je vous propose un retour d'expérience sur la mise en place de projets développés en Quarkus et déployés dans un environnement Cloud.

- [Quarkus ? Késaco ?](#kesaco)
- [Pourquoi utiliser Quarkus ? Dans quel contexte ?](#contexte)
- [Comment mettre en place ? L'heure de la découverte](#decouverte)
- [Alors finalement ? Faisons le bilan](#bilan)


## Quarkus ? Késaco ? <a name="kesaco"></a>

Pour commencer, je vais vous expliquer rapidement ce qu'est Quarkus et pour cela quoi de mieux que de se rendre sur le site du projet [Quarkus](https://quarkus.io/) ?

![frontpage quarkus](/assets/images/quarkus/quarkus-front-page.png)

Waouh ! Ça en jette mais qu'est-ce que ça signifie exactement ?

→ explication rapide terme par terme (pensé pour les environnements serverless, cloud et Kubernetes, java, graalVM, best libraries) + initié par Redhat, framework opensource, ... parler rapidement de WildFly swarm et Thorntail pour l'historique de Quarkus, même lignée que Micronaut

Transition : nous savons ce qu'est Quarkus, nous pouvons commencer le retour d'expérience.

## Pourquoi utiliser Quarkus ? Dans quel contexte ? <a name="contexte"></a>

→ projet legacy en Java migré dans GCP sur AppEngine : projet sans tests (vraiment aucun, oui oui ça existe), pas de framework Spring, Microprofile ou autre, pas d'ORM, un modèle de BDD discutable ... enfin bref pas envie de développer de nouvelles fonctionnalités sur ce projet (peut-être pas nécessaire de s'étendre sur le sujet, juste une courte phrase pour bien faire comprendre que ce projet est gangrené)
-> arrivée d'une nouvelle fonctionnalité : choix à faire de la techno, l'archi etc ; choix de tester Quarkus car volonté de garder un projet Java (pour rester cohérent avec le projet legacy) mais aussi de profiter de la possibilité de faire du serverless simplement via Cloud Run (déjà expérimenté sans succès pour le projet legacy car demandant trop de mémoire : limite à 4Gb pour Cloud Run), voir si c'est un candidat potentiel pour migrer des pans fonctionnels du projet legacy par la suite
-> justifier rapidement le choix de Quarkus par rapport à Micronaut

-> schéma d'archi très simplifié


Transition : nous savons dans quel contexte et pourquoi Quarkus a été choisi mais concrètement, ça se met en place comment ?

## Comment mettre en place ? L'heure de la découverte <a name="decouverte"></a>

→ génération depuis quarkus.io, découverte de toutes les libs sympas déjà intégrées, dockerfile déjà prêt (ou presque), mise en place de tests, déploiement, GraalVM, pb config avec liste d’objets (tweak), peut fonctionner dans JVM mais pas dans GraalVM (voir @RegisterForReflection), CI (besoin de beaucoup de RAM et c’est loooooong), hot code replacement, déploiement dans Cloud Run très simple

Transition : ça tourne depuis quelques mois en prod, l'heure du bilan

## Alors finalement ? Faisons le bilan <a name="bilan"></a>

→ lister rapidement les pour et contre, bonne doc, enthousiaste pour la suite (Redhat), tient ses promesses (temps de démarrage), légers hics mais aujourd'hui ça fonctionne sans accroc en prod
→ difficile à juger car cas d’usage sans vraiment beaucoup de traffic


Sources et liens utiles :

* [Quarkus.io](https://quarkus.io/)
* [Article d'Ippon](https://blog.ippon.fr/2020/04/22/quarkus-est-il-lavenir-de-java/)
* [Article de Zenika](https://blog.zenika.com/2020/07/07/developper-une-application-cloud-ready-avec-quarkus/)
