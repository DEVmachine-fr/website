---
author: Pierre
title: Connecter Firestore avec Google BigQuery pour faire des requêtes SQL avancées
categories: firebase firestore bigquery sql request js javascript
---

Vous avez une application Firebase et vous souhaitez faire des requêtes SQL complexes pour récupérer des données, les formater, faire des jointures ? C’est possible grâce à Google BigQuery et cet article explique comment faire !

- [Introduction <a class="anchor" name="introduction"></a>](#introduction-)
- [Connexion entre Firestore et BigQuery <a class="anchor" name="connect-firestore-bigquery"></a>](#connexion-entre-firestore-et-bigquery-)
  - [Ajout d'une instance BigQuery dans Firestore <a class="anchor" name="firestore-bigquery-instance"></a>](#ajout-dune-instance-bigquery-dans-firestore-)
  - [Importer les données existantes <a class="anchor" name="import-existing-data"></a>](#importer-les-données-existantes-)
  - [Faire des requêtes BigQuery <a class="anchor" name="do-bigquery-requests"></a>](#faire-des-requêtes-bigquery-)
  - [Créer des vues <a class="anchor" name="create-vues"></a>](#créer-des-vues-)
  - [Industrialiser la création de vues par API <a class="anchor" name="create-vues-api"></a>](#industrialiser-la-création-de-vues-par-api-)
- [Utiliser les données BigQuery dans une application <a class="anchor" name="use-bigquery-data"></a>](#utiliser-les-données-bigquery-dans-une-application-)
  - [Ajout d'une clé Google Cloud <a class="anchor" name="add-google-cloud-key"></a>](#ajout-dune-clé-google-cloud-)
  - [Récupérer les données avec une cloud function <a class="anchor" name="get-data-using-cloud-function"></a>](#récupérer-les-données-avec-une-cloud-function-)
- [Conclusion <a class="anchor" name="conclusion"></a>](#conclusion-)
- [Ressources <a class="anchor" name="ressources"></a>](#ressources-)

## Introduction <a class="anchor" name="introduction"></a>

Firestore est une base de données NoSQL qui simplifie souvent le développement d'applications par sa flexibilité. Cependant on peut arriver à une limite quand on veut réaliser des requêtes plus complexes ou des jointures entre différentes collections puisque c'est une base de données non relationnelle.

Une solution pour pallier ce problème est d'utiliser **Google BigQuery**.

BigQuery est une plateforme Cloud de Big Data qui permet le stockage et le "querying" de données. C'est un outil conçu pour permettre des requêtes SQL rapides même avec un ensemble de données massif.

Nous allons donc voir dans cet article comment connecter Firestore et BigQuery, utiliser et requêter nos tables.

## Connexion entre Firestore et BigQuery <a class="anchor" name="connect-firestore-bigquery"></a>

Nous allons lier une collection Firestore avec une table BigQuery.

### Ajout d'une instance BigQuery dans Firestore <a class="anchor" name="firestore-bigquery-instance"></a>

Pour créer un lien entre Firestore et BigQuery, il faut le faire manuellement, collection par collection. L'idée est de n'importer que les collections nécessaires sur BigQuery.

Sur Firebase, dans le menu de gauche cliquez sur Créer > Extensions. En base, cliquez sur "Explorer les extensions Firebase officielles" et dans la nouvelle page qui s'ouvre, choisir "Stream Collections to BigQuery" en cliquant sur "Install".

[![Installation de l'extension](/assets/images/bigquery-firestore/1-install-extension.png)](/assets/images/bigquery-firestore/1-install-extension.png)
*Installation de l'extension*

L’installation se fait en quelques étapes simples, les premières étapes sont pré-remplies et vous pouvez faire "Suivant" jusqu'à la dernière qui permet le configuration de l'extension.

[![Configuration de l'extension](/assets/images/bigquery-firestore/2-configure-extension.png)](/assets/images/bigquery-firestore/2-configure-extension.png)
*Configuration de l'extension*

Il suffit de remplir les champs en choisissant votre *Project Id*, la collection que vous voulez exporter (*Collection path*), le nom de la base de données BigQuery (*Dataset ID*, si la base n'existe pas elle sera automatiquement créée) et le nom de la table BigQuery (*Table ID*, ici aussi la table sera automatiquement créée). Pour terminer, cliquez sur "Installer l'extension". L'installation peut prendre quelques minutes.

Quand l’installation est terminée, se connecter à <a href="https://console.cloud.google.com/" target="_blank">Google Cloud</a> et choisir BigQuery (dans les Accès Rapides ou dans le menu de navigation).

Sur la page BigQuery, vous avez à gauche la liste des projets et en déroulant votre projet, la liste des *datasets* avec au moins un dataset : firestore_export (celui créé lors de l'installation de l'extension). Dans ce dataset, on retrouve les tables créées. Il y a 2 nouvelles tables à chaque nouvelle configuration de l'extension :
- une première qui est suffixée par *_raw_latest* : elle contient toutes les entités de la collection firestore
- une seconde qui est suffixée par *_raw_changelog* : elle contient tout l'historique de modifications de nos entités

Cliquez sur les trois points de votre table *_raw_latest* puis *Interroger*. Une nouvelle fenêtre s'ouvre et permet de requêter la table en SQL.

[![Première requête par défaut BigQuery](/assets/images/bigquery-firestore/3-first-bq-query.png)](/assets/images/bigquery-firestore/3-first-bq-query.png)
*Première requête par défaut BigQuery*

Exécutez cette requête (avec le bouton ou le raccourci clavier *CTRL + Entrée*). Les résultats s'affichent en dessous et... La liste est vide 😬. C'est normal ! La connexion Firestore - BigQuery est active, mais seule les nouvelles données et modifications seront envoyées vers BigQuery. Vous pouvez essayer d'ajouter ou modifier un document dans firestore, puis de relancer la requête BigQuery, cette fois le document concerné devrait apparaître.

### Importer les données existantes <a class="anchor" name="import-existing-data"></a>

Pour tous vos autres documents, pas de panique, il existe une manière de les importer en une seule fois avec le script [fs-bq-import-collection](https://github.com/firebase/extensions/blob/master/firestore-bigquery-export/guides/IMPORT_EXISTING_DOCUMENTS.md).

En suivant les instructions du README, tout devrait bien se passer. Il suffit de lancer le script avec *npc* comme ceci :
`test`

### Faire des requêtes BigQuery <a class="anchor" name="do-bigquery-requests"></a>

### Créer des vues <a class="anchor" name="create-vues"></a>

### Industrialiser la création de vues par API <a class="anchor" name="create-vues-api"></a>

## Utiliser les données BigQuery dans une application <a class="anchor" name="use-bigquery-data"></a>

### Ajout d'une clé Google Cloud <a class="anchor" name="add-google-cloud-key"></a>

### Récupérer les données avec une cloud function <a class="anchor" name="get-data-using-cloud-function"></a>

## Conclusion <a class="anchor" name="conclusion"></a>

## Ressources <a class="anchor" name="ressources"></a>

* [Export Firestore collections to BigQuery and use Data Studio to analyze and aggregate data](https://www.youtube.com/watch?v=u9DfTl5yLLc&ab_channel=RenaudTarnec)