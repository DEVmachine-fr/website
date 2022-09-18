---
author: Julien
title: Migrer vers un Gitlab auto hebergé
categories: gitlab self-hosted gcp
---

Après des années de gratuité, Gitlab modifie les conditions de son offre cloud et limite la gratuité au groupe de moins de 5 personnes : https://about.gitlab.com/blog/2022/03/24/efficient-free-tier/
Avec 19$ par mois par utilisateur, la facture peut très vite devenir salée. Chez devmachine, nous utilisons le service de CI/CD proposé par Gitlab, sans utiliser les registries, la partie Kubernetes et autres services. Nous sommes donc adhérents à l'utilisation de Gitlab. C'est pourquoi nous avons décidé de mettre en place un Gitlab auto-herbergé.
Cet article vous présente l'installation de Gitlab sur un envrionnement GCP, et la migration depuis gitlab.com.

- [Tutoriel d'installation](#tutoriel-installation)
    - [Titre](#lien-titre)
- [Bilan](#bilan)


## Tutoriel d'installation <a class="anchor" name="tutoriel-installation"></a>

### Prérequis <a class="anchor" name="prerequis"></a>

* projet GCP en tant qu'owner (plus simple que d'avoir à ajouter tous les droits unitairement)
* rôle owner sur gitlab.com

### Installation de Gitlab sur une VM <a class="anchor" name="installation-gitlab-sur-vm"></a>

Pourquoi sur une VM ? Moins gourmand en ressources que dans Kubernetes
Créer une VM compute engine (avec captures d'écran) -> autoriser http et https pour let's encrypt
Ajout DNS de l'IP externe
Install omnibus gitlab : suivre tuto gitlab : https://about.gitlab.com/install/, https://about.gitlab.com/install/#ubuntu
Passer la partie postfix, utilisation du smtp relay google

### Configuration SMTP <a class="anchor" name="configuration-smtp"></a>

Setup google SMTP relay https://support.google.com/a/answer/2956491

### Cloud SQL or not <a class="anchor" name="cloud-sql-or-not"></a>

Setup cloud sql : https://docs.gitlab.com/ee/install/postgresql_extensions.html, user gitlab, penser à disable postgres et postgres exporter
Performances terribles, plus de 5 secondes de latence
Décision de rester sur un postgre local

### Migration depuis gitlab.com <a class="anchor" name="migration-gitlab"></a>

Migrate groups : https://docs.gitlab.com/ee/user/group/import/
-> attention, pas de migration des projets ni des utilisateurs, juste l'arbo des groupes/sous-groupes
Ajout app côté gitlab.com (https://gitlab.devmachine.fr/help/integration/gitlab) https au lieu de http dans les redirect uris (nécessaire pour faire le transfert)
Migrate projects : https://docs.gitlab.com/ee/user/project/import/gitlab_com.html

### Gitlab runners dans Kubernetes

Setup runners (voir fichier helmfile, avec cloud storage pour le cache, création du cluster avec option spot)

### Oauth

Setup OAUTH (https://docs.gitlab.com/ee/integration/google.html)

### Création des utilisateurs

Création de tous les utilisateurs + leur demander d'associer à leurs comptes GOOGLE

### Pense-bêtes <a class="anchor" name="pense-betes"></a>

tail
reconfigure
nv -vz ip port
sudo gitlab-rake "gitlab:password:reset[root]"

## Bilan <a class="anchor" name="bilan"></a>


Coûts : vm + kubernetes
VS
19$ par mois par user

Avantages/Inconvénients
+ autant d'users qu'on le souhaite (besoin d'upgrader la VM si besoin)
- upgrade manuel (semble bien géré dans omnibus)
- maintenance à assurer
