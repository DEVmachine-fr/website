---
author: Julien
title: Migrer vers un Gitlab auto hebergé
categories: gitlab self-hosted gcp
---

Après des années de gratuité, Gitlab modifie les conditions de son offre cloud et limite la gratuité au groupe de moins de 5 personnes : https://about.gitlab.com/blog/2022/03/24/efficient-free-tier/
Avec 19$ par mois par utilisateur, la facture peut très vite devenir salée. Chez DEVmachine, nous utilisons Gitlab pour héberger notre code, gérer nos merge requests et pour faire tourner notre CI/CD. Notre seule adhérence à Gitlab concerne notre CI/CD. Migrer sur une autre solution de CI/CD demanderait un effort conséquent. Afin de limiter les coûts, nous avons décidé de mettre en place un Gitlab auto-herbergé.
Cet article vous présente l'installation de Gitlab sur un envrionnement Google Cloud Platform (GCP), la migration depuis gitlab.com et dresse le bilan de l'effort.

- [Tutoriel d'installation](#tutoriel-installation)
- [Migration depuis gitlab.com](#migration-gitlab)
    - [Titre](#lien-titre)
- [Bilan](#bilan)


## Tutoriel d'installation <a class="anchor" name="tutoriel-installation"></a>

### Prérequis <a class="anchor" name="prerequis"></a>

* avoir un projet GCP existant
* avoir le rôle de propriétaire sur ce projet
* avoir le rôle owner, du groupe à migrer, sur gitlab.com
* posséder un nom de domaine dédié

### Que va-t-on installer ? <a class="anchor" name="installer-quoi"></a>

Gitlab est composé de plusieurs composants. En voici une architecture simplifiée :

[![Architecture simplifiée Gitlab](https://docs.gitlab.com/ee/development/img/architecture_simplified_v14_9.png)](https://docs.gitlab.com/ee/development/img/architecture_simplified_v14_9.png)

L'idée n'est pas de décrire chaque composant mais de comprendre que de nombreuses briques doivent être assemblées pour installer Gitlab. Mais nous verrons que Gitlab fournit un script simple d'utilisation, ainsi qu'un chart helm.
Si vous désirez plus de détails sur son architecture, je vous renvoie vers la documentation officielle : https://docs.gitlab.com/ee/development/architecture.html, d'où j'ai tiré le schéma ci-dessus.


### Installation de Gitlab sur une VM <a class="anchor" name="installation-gitlab-sur-vm"></a>

Nous avons fait le choix d'installer Gitlab sur une machine virtuelle pour deux raisons :
* les ressources recommandées sont moins importantes sur une VM que sur Kubernetes : 2 noeuds avec 2 CPU et 15 Go de mémoire sur Kubernetes contre 1 VM avec 4 CPU et 4 Go de mémoire. Dans notre cas, nous verrons qu'il n'est pas nécessaire d'allouer autant de CPU. Les coûts associés sont donc moins importants, au détriment de la résilience.
* Gitlab propose un script d'installation simple d'utilisation, sans s'embarasser de la complexité induite par Kubernetes. Pour une première installation de l'écosystème Gitlab, ce script simplifie grandement la tâche. Gitlab propose également un chart helm d'installation si vous choisissez de l'installer sur Kubernetes.

Nous commençons donc par créer la VM dans Compute Engine.

[![Création de la VM dans compute engine](/assets/images/blog/gitlab/create-vm-compute-engine.png)](/assets/images/blog/gitlab/create-vm-compute-engine.png)

Nous n'avons pas suivi les recommandations de Gitlab (😈) et créé une instance avec 2 CPU et 8 Go de mémoire. Il y a quelques points importants à suivre lors de la création de la VM :
* il faut autoriser le traffic HTTP et HTTPS au niveau du pare-feu. L'autorisation HTTP sera nécessaire pour la création des certificats let's encrypt plus tard.
* il faut allouer une adresse IP privée à votre VM sur le réseau de votre choix. Cette IP permettra de communiquer avec la base de données PostgreSQL installée sur Cloud SQL comme nous le verrons plus tard.

Cette ligne de commande permet de créer la VM :

```
gcloud compute instances create gitlab --project=${your-projetc} --zone=europe-west1-b --machine-type=e2-standard-2 --network-interface=network-tier=PREMIUM,subnet=default --maintenance-policy=MIGRATE --provisioning-model=STANDARD --service-account=${dedicated-service-account} --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=http-server,https-server --create-disk=auto-delete=yes,boot=yes,device-name=gitlab,image=projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20220927,mode=rw,size=100,type=projects/${your-project}/zones/europe-west1-b/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
```

Une fois la VM créée, vous pourrez ajouter son IP externe dans vos entrées DNS, en lui allouant le domaine de votre choix.
Dans notre cas, nous avons ajouté cette entrée à notre DNS :

```
gitlab.devmachine.fr A 35.233.49.198
```

Il ne restera plus qu'à vous connecter en SSH sur la machine et à exécuter les instructions décrites sur la page https://about.gitlab.com/install/.
Et plus spécifiquement sur la page https://about.gitlab.com/install/#ubuntu dans notre cas.

Étant donné que nous utilisons Google Workspace chez DEVmachine, nous n'avons pas installé postfix et avons préféré passer le relais SMTP de Google.

### Configuration SMTP <a class="anchor" name="configuration-smtp"></a>

Pour que Gitlab se serve du relais SMTP de Google pour envoyer des mails, il est nécessaire de configurer ce relais côté Google Workspace. Pour cela, il est nécessaire d'être administrateur de Google Workspace. Suivez les instructions présentes ici : https://support.google.com/a/answer/2956491 pour configurer votre relais SMTP comme vous le voulez.

Il faudra ensuite configurer Gitlab pour utiliser ce relais en appliquant cette configuration : https://docs.gitlab.com/omnibus/settings/smtp.html#google-smtp-relay.
Dans notre cas, voici la configuration appliquée :

```
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp-relay.gmail.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_domain'] = "devmachine.fr"
gitlab_rails['gitlab_email_from'] = 'gitlab@devmachine.fr'
```

En l'état, Gitlab est fonctionnel. Sa base de données PostgreSQL tourne sur la VM aux côtés des autres services. Il nous reste à configurer la mise en place des dumps, s'assurer de la réplication de la base sur une autre instance ou bien ...


### Cloud SQL <a class="anchor" name="cloud-sql"></a>

Ou bien nous pouvons éviter tout cela en utilisant le service, fourni par GCP, Cloud SQL pour assurer la maintenance et la résilience de notre base de données.

Pour créer la base de données, vous pouvez suivre la documentation Cloud SQL : https://cloud.google.com/sql/docs/postgres/create-manage-databases?hl=fr. Nous avons donc créé une instance PostgreSQL 14, à laquelle nous avons alloué 1 CPU et 4 Go de mémoire. Nous lui avons alloué une adresse IP privée sur le même réseau que la VM gitlab, la VM pourra donc communiquer directement avec cette instance en utilisant son adresse IP. La disponibilité élevée a été activée afin d'assurer le basculement vers une instance répliquée en cas de panne sur la première instance.

Une fois l'instance créée, il faut créer l'utilisateur `gitlab` avec le mot de passe de votre choix. Il faut également créer la base de données `gitlabhq_production`.

Ensuite connectez vous à l'instance avec l'utilisateur gitlab et activez les extensions PostgreSQL nécessaires à Gitlab : https://docs.gitlab.com/ee/install/postgresql_extensions.html.

Enfin, il faut configurer Gitlab pour utiliser cette instance. Il faut penser à désactiver le composant `postgres` et `postgres_exporter` côté Gitlab.
Dans notre cas, ça donne ça :

```
# Disable the built-in Postgres
postgresql['enable'] = false
postgres_exporter['enable'] = false

# Fill in the connection details for database.yml
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'utf8'
gitlab_rails['db_host'] = '${ip-interne-instance-cloud-sql}'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = '${password-tres-tres-secure}'
```

### Oauth

TODO
Setup OAUTH (https://docs.gitlab.com/ee/integration/google.html)


### Gitlab runners dans Kubernetes

Setup runners (voir fichier helmfile, avec cloud storage pour le cache, création du cluster avec option spot)



## Migration depuis gitlab.com <a class="anchor" name="migration-gitlab"></a>

Migrate groups : https://docs.gitlab.com/ee/user/group/import/
-> attention, pas de migration des projets ni des utilisateurs, juste l'arbo des groupes/sous-groupes
Ajout app côté gitlab.com (https://gitlab.devmachine.fr/help/integration/gitlab) https au lieu de http dans les redirect uris (nécessaire pour faire le transfert)
Migrate projects : https://docs.gitlab.com/ee/user/project/import/gitlab_com.html

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
