---
author: Julien
title: Migrer vers un Gitlab auto hebergé
categories: gitlab self-hosted gcp
---

Après des années de gratuité, Gitlab modifie les conditions de son offre cloud et limite la gratuité au groupe de moins de 5 personnes : https://about.gitlab.com/blog/2022/03/24/efficient-free-tier/
Avec 19$ par mois par utilisateur, la facture peut très vite devenir salée. Chez DEVmachine, nous utilisons Gitlab pour héberger notre code, gérer nos merge requests et pour faire tourner notre CI/CD. Notre seule adhérence à Gitlab concerne notre CI/CD. Migrer sur une autre solution de CI/CD demanderait un effort conséquent. Afin de limiter les coûts, nous avons décidé de mettre en place un Gitlab auto-herbergé.
Cet article vous présente l'installation de Gitlab sur un envrionnement Google Cloud Platform (GCP), la migration depuis gitlab.com et dresse le bilan de l'effort.

- [Tutoriel d'installation](#tutoriel-installation)
    - [Prérequis](#prerequis)
    - [Que va-t-on installer ?](#installer-quoi)
    - [Installation de Gitlab sur une VM](#installation-gitlab-sur-vm)
    - [Configuration SMTP](#configuration-smtp)
    - [Cloud SQL](#cloud-sql)
    - [OAuth 2](#oauth)
    - [Runners dans Kubernetes](#runners-dans-kubernetes)
    - [Pense-bête](#pense-bete)
- [Migration depuis gitlab.com](#migration-gitlab)
    - [Migration des groupes](#migration-groupes)
    - [Migration des projets](#migration-projets)
    - [Création des utilisateurs](#creation-des-utilisateurs)
    - [Archivage gitlab.com](#archivage)
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

# Cloud SQL configuration
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'utf8'
gitlab_rails['db_host'] = '${ip-interne-instance-cloud-sql}'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = '${password-tres-tres-secure}'
```

### OAuth 2 <a class="anchor" name="oauth"></a>

Pour activer l'OAuth avec votre compte Google, la documentation de Gitlab est très claire, vous pouvez la retrouver ici : https://docs.gitlab.com/ee/integration/google.html. Veillez à remplacer `http` par `https` dans les redirect URI fournis. 

Pour simplifier la mise en place de l'OAuth 2, nous avons choisi de réserver cette authentification aux personnes de DEVmachine, en gardant le type d'utilisateur à interne. Ainsi les personnes externes à l'entreprise qui seront ajoutées au Gitlab DEVmachine ne bénéficieront pas de la possibilité de s'identifier par OAuth 2.

Vous devrez retrouver ces paramètres dans votre configuration Gitlab après la mise en place de l'OAuth 2 :

```
gitlab_rails['omniauth_providers'] = [
  {
    name: "google_oauth2",
    # label: "Provider name", # optional label for login button, defaults to "Google"
    app_id: "YOUR_APP_ID",
    app_secret: "YOUR_APP_SECRET",
    args: { access_type: "offline", approval_prompt: "" }
  }
]
```

### Runners dans Kubernetes <a class="anchor" name="runners-dans-kubernetes"></a>

Nous avons fait le choix de déployer les runners dans Kubernetes. Plutôt que de monter des VM puissantes qui tourneraient en permanence et qui limiteraient le nombre d'exécutions de job en parallèle par leurs ressources, Kubernetes permet d'adapter le nombre de noeuds en fonction du nombre de jobs. C'est à dire que si aucun job ne tourne à un instant T, le nombre de noeuds dédié aux runners tombe à 0 et n'engendre donc aucun coût. Si 8 jobs doivent tourner en parallèle, Kubernetes va adapter le nombre de noeuds nécessaires pour que ces jobs puissent tourner en parallèle.

Toutefois, cette configuration nécessite d'avoir un runner qui tourne toujours dans le cluster Kubernetes. Ce runner est en charge de poller Gitlab pour dépiler les jobs en attente d'exécution et déclencher la création des pods d'exécution des jobs. Nous avons placé ce runner sur un noeud déjà existant, sur lequel d'autres outils sont déployés.

Pour plus de détails sur le fonctionnement des runners dans Kubernetes, vous pouvez consulter la documentation officielle : https://docs.gitlab.com/runner/executors/kubernetes.html.

Concrètement, nous avons déployé ces runners à l'aide du chart fourni par Gitlab : https://gitlab.com/gitlab-org/charts/gitlab-runner.

Nous avons utilisé helmfile et voici le contenu du fichier de values associé au chart :

```
concurrent: 10

gitlabUrl: https://gitlab.devmachine.fr

rbac:
  create: true

runnerRegistrationToken: ${registration-token}

runners:
  config: |
    [[runners]]
      [runners.kubernetes]
        namespace = "{{.Release.Namespace}}"
        image = "alpine:latest"
        privileged = true
        poll_timeout = 600
        cpu_request = "500m"
        cpu_limit = "1"
        memory_request = "2Gi"
        memory_request_overwrite_max_allowed = "4Gi"
        memory_limit = "4Gi"
        memory_limit_overwrite_max_allowed = "6Gi"
        service_cpu_request = "100m"
        service_cpu_limit = "500m"
        service_memory_request = "512Mi"
        service_memory_limit = "1Gi"
        helper_cpu_request = "100m"
        helper_cpu_limit = "500m"
        helper_memory_request = "512Mi"
        helper_memory_limit = "1Gi"
        [runners.kubernetes.node_selector]
          type = "gitlab-runner"
        [runners.kubernetes.node_tolerations]
          "type=gitlab-runner" = "NoSchedule"
        [runners.cache]
          Type = "gcs"
          Path = "gitlab-runner"
          Shared = false
          [runners.cache.gcs]
            AccessID = "${dedicated-service-account}"
            PrivateKey = "${service-account-private-key}"
            BucketName = "dm-gitlab-runners-cache"

```

L'option `concurrent: 10` permet de limiter le nombre de jobs en parallèle que ce runner fera tourner à 10.

Le `runnerRegistrationToken` correspond au token qui permet d'enregistrer ce runner aurpès de Gitlab, ce token est généré côté Gitlab.

Comme vous pouvez le constater, les runners vont tourner sur un pool de noeuds spécifique de `type=gitlab-runner`, ce pool de noeuds a été créé avec l'option `spot` pour limiter les coûts des runners au maximum. Les VM spot sont des VM moins chères qui ne garantissent aucune disponibilité, vous trouverez plus de détails ici : https://cloud.google.com/kubernetes-engine/docs/concepts/spot-vms. Un point à noter est la possibilité d'augmenter les `memory_request` et `memory_limit` dans les fichiers `.gitlab.ci.yml`, respectivement jusqu'à 4Gi et 6Gi. Cela laisse la possibilité d'utiliser plus de mémoire pour des jobs nécessitant plus de mémoire, sans avoir à définir un nouveau runner accompagné d'un pool de noeuds plus puissants par exemple.

Enfin le cache est configuré sur le bucket Cloud Storage `dm-gitlab-runners-cache`.

### Pense-bête <a class="anchor" name="pense-bete"></a>

J'ai noté ici quelques commandes utiles qui pourront vous aider pendant l'installation de votre instance Gitlab :

* Pour suivre les logs des différents composants de gitlab

```
sudo gitlab-ctl tail
```

* Pour redémarrer gitlab après la modification du fichier de configuration

```
sudo gitlab-ctl reconfigure
```

* Pour tester la connexion sur le port d'une machine avec une ip

```
nc -vz ip port
```

* Pour réinitialiser le mot de passe de l'utilisateur root (mais vous n'en aurez pas besoin car vous l'aurez précieusement stocké quelque part 😇)

```
sudo gitlab-rake "gitlab:password:reset[root]"
```

## Migration depuis gitlab.com <a class="anchor" name="migration-gitlab"></a>

Avant d'entamer la migration, il est nécessaire de permettre à votre instance Gitlab de se connecter à gitlab.com en suivant cette procédure : https://{your-gitlab-domain}/help/integration/gitlab. Veillez à remplacer `http` par `https` dans les redirect URI fournis.

À la fin de la procédure, vous aurez la configuration suivante :

```
gitlab_rails['omniauth_providers'] = [
  {
    name: "gitlab",
    # label: "Provider name", # optional label for login button, defaults to "GitLab.com"
    app_id: "YOUR_APP_ID",
    app_secret: "YOUR_APP_SECRET",
    args: { scope: "read_user" } # optional: defaults to the scopes of the application
  },
  {
    name: "google_oauth2",
    # label: "Provider name", # optional label for login button, defaults to "Google"
    app_id: "YOUR_APP_ID",
    app_secret: "YOUR_APP_SECRET",
    args: { access_type: "offline", approval_prompt: "" }
  }
]
```

### Migration des groupes <a class="anchor" name="migration-groupes"></a>

Pour commencer à migrer depuis gitlab.com, il faut commencer par migrer les groupes et les sous-groupes. Si tous vos projets sont dans le même groupe et qu'aucun sous-groupe n'existe, vous pouvez passer cette étape.

Le processus de migration des groupes est décrit ici : https://docs.gitlab.com/ee/user/group/import/.

[![Import des groupes](/assets/images/blog/gitlab/import-groups.png)](/assets/images/blog/gitlab/import-groups.png)

Seuls les groupes et les sous-groupes seront migrés, les variables définies pour la CI/CD ne sont pas migrées, il faut les recréer manuellement. Les utilisateurs et les projets ne sont pas migrés.

### Migration des projets <a class="anchor" name="migration-projets"></a>

La migration des projets est assez fastidieuse si vous avez beaucoup de projets à migrer. La procédure est décrite ici : https://docs.gitlab.com/ee/user/project/import/gitlab_com.html. Il va falloir replacer chaque projet dans son groupe/sous-groupe de destination.

[![Import des projets](/assets/images/blog/gitlab/import-projects.png)](/assets/images/blog/gitlab/import-projects.png)

De la même façon que pour les groupes, les variables définies pour la CI/CD ne sont pas migrées et il faut les recréer manuellement.

### Création des utilisateurs <a class="anchor" name="creation-des-utilisateurs"></a>

Vous allez maintenant pouvoir créer les comptes des utilisateurs depuis l'interface d'administration de votre Gitlab. Il est également possible d'ouvrir l'inscription publique à votre gitlab. En tant qu'administrateur, vous pourrez choisir d'accepter ces nouveaux utilisateurs. 

Les nouveaux utilisateurs recevront un mail pour valider la création de leur compte et configurer leur mot de passe.

[![Import des projets](/assets/images/blog/gitlab/mail-creation.png)](/assets/images/blog/gitlab/mail-creation.png)

### Archivage gitlab.com <a class="anchor" name="archivage"></a>

Une fois l'opération de migration terminée, vous allez pouvoir archiver les projets côté gitlab.com pour que les utilisateurs ne poussent pas par inadvertance sur le mauvais gitlab.

Je vous conseille également de fournir un script à tous les utilisateurs pour modifier le remote origin de tous leurs repositories.

```
TODO SCRIPT A AJOUTER
```

## Bilan <a class="anchor" name="bilan"></a>

Installer un gitlab auto-hebergé et migrer depuis gitlab.com n'est pas une mince affaire. Au delà du temps d'installation et de migration, il vous faudra sans doute passer du temps pour ajuster les ressources allouées à vos runners, monitorer et superviser les différents composants etc.

Le coût d'infrastructure n'est pas négligeable non plus, avec notamment les coûts de : la base de données Cloud SQL, la VM Compute Engine, le pool de noeuds des runners dans Kubernetes.

De plus, Gitlab publie régulièrement des versions correctives qui nécessitent la mise à jour de Gitlab avec un arrêt de service.

Avoir un gitlab auto-hebergé présente son lot d'inconvénients. Cependant, une fois installée et configurée correctement, vous êtes libres d'ajouter autant d'utilisateurs que vous le souhaitez, en accordant les ressources de l'infrastructure à ce nombre d'utilisateurs bien entendu, sans avoir à payer 19$ par mois pour chaque nouvel utilisateur.

En terme de coûts, l'installation d'un gitlab auto-hebergé ne semble être rentable qu'à partir d'un certain nombre d'utilisateurs. Si vous avez moins de 20 utilisateurs, il est sans doute préférable de rester sur gitlab.com. Les coûts d'infrastructure et le temps investi seront à peu près équivalents sur le moyen terme. Toutefois, si vous n'utilisez pas la CI de Gitlab, il existe des alternatives moins onéreuses pour héberger votre code et gérer vos merge/pull requests.
