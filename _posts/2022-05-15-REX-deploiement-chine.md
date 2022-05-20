---
author: Olivier
title: REX - déployer une app en Chine 
categories: cloud kubernetes gcp alibaba chine icp
---


Cet article a pour but de faire un retour d'expérience sur le déploiement d'applications (web & mobile) dans deux clouds (GCP et Alibaba), à destination d'utilisateurs européens et chinois.

- [Introduction](#introduction)
- [Choix du (des) Cloud Provider(s)](#cloud-providers)
- [Offres GCP vs Alibaba Cloud](#offres)
- [Mise en service](#mise-en-service)
- [DevOps](#devops)
- [Applications mobiles](#applications-mobiles)

## Introduction <a class="anchor" name="introduction"></a>

Dans le cadre du développement d'un produit pour des utilisateurs répartis dans plusieurs pays du monde, j'ai été confronté à une problématique principale et assez méconnue pour nous : déployer des applications web et mobiles à destination d'utilisateurs sur le territoire chinois. L'objectif ici est de dresser un retour d'expérience sur ces problématiques et lever quelques pièges dans lesquels je suis tombé.
Cet article sera aussi l'occasion d'établir quelques points de comparaison entre deux cloud providers : Google Cloud Platform (GCP) et Alibaba Cloud.


## Choix du (des) Cloud Provider(s) <a class="anchor" name="cloud-providers"></a>

La première étape du déploiement de nos applications a été de les commercialiser en premier lieu en France.
Il nous fallait donc l'héberger quelque part. La question de l'hébergement on-premise a été écartée dès le début, car les infrastructures internes vieillissantes de l'entreprise cliente n'étaient pas préparées à ce type de besoin (et les ressources matérielles et humaines pour la faire évoluer n'existaient pas). Un déploiement dans le cloud était donc vite acté, restait à choisir le provider. 

Afin de pouvoir le choisir, nous avions une principale contrainte : déployer notre stack applicative dans kubernetes. Cet article n'a pas pour objectif de décrire cette décision, nous le prenons donc ici comme prérequis :-)

Nous sommes à ce moment en début d'année 2018, et les cloud providers proposant une offre kubernetes managé ne sont pas du tout aussi nombreux qu'aujourd'hui ! Google était présent depuis 2015 avec son offre GKE (Container Engine à cette époque), Amazon EKS et Azure AKS venaient à peine d'annoncer leurs offres. [1]

Les premiers clusters de test de cette époque n'existent plus, mais celui de prod a quelques années maintenant...
```
$ gcloud container clusters describe prod --zone=us-east1-b --format "value(createTime)"
2018-05-14T07:28:23+00:00
```

A ma connaissance, aucun des autres acteurs du moment n'étaient présents à ce moment (OVH, Scaleway, Exoscale, etc).

Le début de l'aventure commence, les premiers utilisateurs sont là !

Des mois passent et le temps est venu de vendre notre application aux premiers clients chinois. Nous savons que les règles sont quelque peu différentes en Chine, il est temps de s'y plonger vraiment.

Bien qu'il ne fut pas très facile d'obtenir des informations claires (en anglais ou français), notre analyse du sujet nous a orienté vers une obligation de stocker les données de nos utilisateurs sur le territoire chinois. GCP proposant une zone Asiatique, mais pas sur le territoire chinois, nous sommes partis en quête d'un provider chinois proposant une offre kubernetes managé (autant profiter de tout le travail déjà effectué sur GCP pour redéployer dans un second cluster). Trois possibilités sont apparues :
- Alibaba Cloud (ACK)
- Huawei Cloud (CCE)
- Tencent Cloud (TKE)

Le choix entre ces trois solutions n'a presque porté que sur un critère : la documentation. Bien qu'une grande partie de la documentation d'Alibaba soit encore en chinois en 2019, la partie en anglais était sans commune mesure avec celle de Huawei ou Tencent, où osons le dire, nous ne pouvions rien faire sans Google Translate.

## Offres GCP vs Alibaba Cloud <a class="anchor" name="offres"></a>

L'offre Alibaba Cloud est très similaire à ce que peut proposer Google Cloud (et les autres). De manière non exhaustive, on y trouve : 
- des VMs
- du Kubernetes managé
- du storage en buckets
- une offre messaging (Pub/Sub)
- une stack réseau similaire (VPC, VPN, Load Balancer, etc)
- Domaines et DNS
- etc

La différence se fait en revanche plus sur les implémentations, la documentation et la présentation.
En ce qui concerne la présentation, Google Cloud est beaucoup plus épuré. Les pages de la console sont légères et il est facile d'y trouver l'information. De plus, il existe souvent une aide contextuelle qui permet de comprendre rapidement le fonctionnement. En cas de besoin plus précis, il existe une documentation très complète, et en français. En comparaison, Alibaba possède une console beaucoup plus chargée, avec énormément d'informations pour lesquelles la signification n'est pas toujours claire. Les aides contextuelles ne sont pas claires, mais il existe des renvois à la documentation complète.

[![Page de création de cluster kubernetes sur GCP](/assets/images/REX-deploiement-chine/screenshot-new-cluster-gcp.png)](/assets/images/REX-deploiement-chine/screenshot-new-cluster-gcp.png)
*Page de création de cluster kubernetes sur GCP*

[![Page de création de cluster kubernetes sur Alibaba](/assets/images/REX-deploiement-chine/screenshot-new-cluster-alibaba.png)](/assets/images/REX-deploiement-chine/screenshot-new-cluster-alibaba.png)
*Page de création de cluster kubernetes sur Alibaba*

Le problème pour nous a été qu'en 2019, cette documentation n'était pas en français, et surtout pas complètement en anglais non plus. Il nous a fallu utiliser de la traduction automatique par moments. La console Alibaba a été buguée à plusieurs reprises, avec des codes de traduction apparaissant au lieu des libellés ou des termes anglais s'affichant en chinois... Tout cela n'était pas forcément très accessible, mais il faut bien avouer qu'elle s'est grandement améliorée depuis ce temps. Aujourd'hui la documentation en anglais ne laisse plus de trace de chinois, y compris dans les captures d'écrans.

Un autre point en défaveur d'Alibaba est la tarification. Google, Amazon et Azure sont réputés pour avoir des systèmes de tarification complexes, et savoir ce que l'on va payer à l'avance est quasi impossible. C'est encore pire chez Alibaba ! Il n'existe par exemple pas de simulateur de coût comme on trouve chez GCP [2] Et le modèle de tarification n'est pas toujours très clair. Par exemple, la [page expliquant l'utiisation des *Reserved Instances*](https://www.alibabacloud.com/help/en/doc-detail/100373.html) n'est pas forcément simple à comprendre avec beaucoup de tableaux et d'alternatives à prendre en compte.

## Mise en service <a class="anchor" name="mise-en-service"></a>

En Chine, il y a quelques petits pièges à anticiper !

Le premier est que pour acheter le moindre produit en Chine continentale (exception pour Hong Kong), il faut remplir un formulaire appelé [Real-Name Registration](https://www.alibabacloud.com/help/en/doc-detail/52595.htm). Pensez-bien à anticiper, le délai de vérification est de quelques jours...


Ensuite, lorsque vous déployez vos premières instances ou nœuds k8s, il faut les connecter à Internet si vous souhaitez y avoir accès depuis vos nœuds (par exemple pour télécharger les images docker). Ceci passe par la création d'une [NAT Gateway](https://www.alibabacloud.com/help/en/product/44413.html) qui vous coûtera déjà plusieurs dizaines de dollars par mois (le prix est aussi très variable en fonction de la région).

De plus, en créant votre premier Load Balancer, vous penserez pouvoir accéder à votre site web quelques secondes ou minutes après. C'est sans compter le filtrage du gouvernement et les vérifications administratives. Il faudra montrer pattes blanches et fournir quelques documents administratifs (du type passeport, SIRET) pour que l'accès y soit autorisé.

Enfin, le dernier point sensible est l'enregistrement du nom de domaine. Notre première idée a été de réserver notre .cn sur notre registrar habituel, c'est-à-dire OVH. Avant qu'il puisse fonctionner, il nous a fallu fournir via le ticketing OVH les passeports du directeur de l'entreprise, les SIRET de l'entreprise, un document justifiant la présence de locaux sur le territoire chinois. Cette étape a été longue et compliquée, OVH ne semblant pas forcément rodé à cette activité. OVH ne fait que *passe-plat* vers le registrar chinois, donc les échanges sont laborieux. Mention spéciale pour le registrar chinois qui refuse les PDF, seuls les JPG de moins de 1 Mo sont acceptés...

Après quelques semaines de tâtonnements nous avions enfin réussi à ouvrir notre service ! Quelle fierté, il aura fallu de la persévérance... Mais nous n'avions pas pour autant fini les découvertes. Chaque année, au moment du renouvellement du domaine, notre service était coupé sans aucune notification ! Il s'agissait en fait de renvoyer un extrait SIRET renouvelé, de moins de trois mois (toujours en jpg, via le ticketing d'OVH, qui accessoirement n'autorise pas les pièces jointes, il faut donc passer par un deuxième canal, l'email) ! Donc chaque année, une semaine de coupure sans que nous puissions faire quoi que ce soit pour améliorer la chose.

Au bout de trois ans et comprenant qu'OVH ne pourrait rien pour nous, nous avons décidé de migrer le domaine chez Alibaba. Cette fois tout a fonctionné du premier coup, ce qui parait logique puisque nous avions déjà procédé aux *Real-name Registration* sur leurs services.

Nous avons fait le choix d'héberger notre service sur la région Hong Kong pour plusieurs raisons : 
 - les coûts sont plus faibles
 - Google n'y est pas bloqué (pratique lorsque l'on veut intéragir avec d'autres ressources hébergées chez GCP)
 - l'ICP n'est pas obligatoire

L'ICP a été une n-ième difficulté du déploiement en Chine. Il s'agit d'une licence pour être *Internet Content Provider" ou Fournisseur de Service Internet qui concerne toute personne ou entreprise qui veut être visible sur le Web depuis la Chine continentale. Il s'agit d'un document à remplir auprès du Ministère de l'Industrie et des Technologies de l'Information (Ministry of Industry and Information Technology, MIIT), qui n'existe qu'en chinois !
Alibaba fournit un [service pour faciliter la demande d'ICP](https://beian.aliyun.com/?spm=5176.12818093.top-nav.dicp.16a812d2Yn2nOB), mais le service reste en chinois.
Le service officiel se trouve sur le [site du Ministère](https://beian.miit.gov.cn/#/Integrated/index).

## DevOps <a class="anchor" name="devops"></a>

Que ce soit GCP ou Alibaba, les deux proposent ce qu'il faut pour adopter une démarche DevOps. Ils fournissent une CLI, des APIs, ainsi que des providers Terraform. Attention toutefois, le [provider Terrafom pour GCP](https://registry.terraform.io/providers/hashicorp/google/) est officiellement supporté par HashiCorp alors que [celui d'Alibaba](https://registry.terraform.io/providers/aliyun/alicloud) est directement maintenu par Alibaba.
De même que pour la console Web ou CLI, le provider Google est, à l'usage, beaucoup plus simple à prendre en main que celui d'Alibaba.

Petite chose à noter : Alibaba Cloud s'appelle également Aliyun (surtout en chine semble t-il), voire AliCloud. Lorsque vous cherchez un outil, un SDK ou autre, pensez à essayer avec les trois noms :)

## Applications Mobiles <a class="anchor" name="applications-mobiles"></a>

En ce qui concerne le déploiement des applications mobiles, il y a également des subtilités à connaitre avant de se lancer.
Tout d'abord, il n'y a pas d'accès à Google en Chine et donc pas d'accès au Play Store. À la place, chaque constructeur de téléphone (Huawei, Tencent, Samsung, Oppo, etc) fournit son propre *app store*. En ce qui nous concerne, nous avons restreint notre déploiement au Huawei Store car nos utilisateurs s'en servent principalement. Mais si vous voulez déployer une application à plus large échelle, il faudra prévoir les processus de déploiement sur chaque store, ce qui peut prendre un peu de temps.

Ensuite chaque constructeur va également établir ses propres règles de validation. S'il est assez simple de déployer une application sur le Play Store, il n'en est pas forcément autant sur le Huawei Store (qui se rapprocherait plus de ce que fait Apple). Voici par exemple une liste de points que nous avons découverts au fil du temps : 
- obligation de fournir un compte utilisateur (login/password) valide pour qu'un opérateur (ça ne semble pas être un robot) valide le bon fonctionnement de l'application
- ce compte doit présenter des informations réelles sinon l'application sera refusée, il faut donc prévoir aussi des jeux de données
- bien sûr, si vous oubliez de traduire des termes en chinois, vous aurez des soucis
- les mentions légales doivent être accessibles depuis la première page de votre application (avant le login si applicable)
- les mentions légales doivent aussi être accessibles sur une simple URL (pas uniquement dans l'apk)
- si vous publiez plusieurs applications avec une base de code identique, vous aurez également des problèmes, car l'outil de validation les considèrera comme des doublons (et il vous faudra passer par de fastidieux échanges via des tickets de support)

Enfin, et malgré tous les efforts possibles, la validation semble rester manuelle. Donc les approbations ou refus sont aléatoires en fonction des jours ou opérateurs. Une application acceptée un jour peut ne pas l'être le lendemain, par exemple, car l'opérateur ne tape pas le bon mot de passe (oui, nous l'avons vécu).

## Conclusion

En conclusion, nous avons réussi à fournir notre service en Chine, mais tout y parait compliqué d'un point de vue administratif ou légal.
Si vous vous lancez dans une telle aventure, je vous conseille de prévoir un peu de marge pour absorber les désagréments que vous pourrez subir, la route ne sera pas aussi droite que ce que l'on peut connaitre habituellement.

## Notes

1. [1] [https://cloudplatform.googleblog.com/2015/08/Google-Container-Engine-is-Generally-Available.html](https://cloudplatform.googleblog.com/2015/08/Google-Container-Engine-is-Generally-Available.html)
   [https://aws.amazon.com/fr/about-aws/whats-new/2017/11/introducing-amazon-elastic-container-service-for-kubernetes/](https://aws.amazon.com/fr/about-aws/whats-new/2017/11/introducing-amazon-elastic-container-service-for-kubernetes/)
   [https://azure.microsoft.com/fr-fr/blog/introducing-azure-container-service-aks-managed-kubernetes-and-azure-container-registry-geo-replication/](https://azure.microsoft.com/fr-fr/blog/introducing-azure-container-service-aks-managed-kubernetes-and-azure-container-registry-geo-replication/)
{: .text-left}


2. [2] [https://cloud.google.com/products/calculator/](https://cloud.google.com/products/calculator/)
