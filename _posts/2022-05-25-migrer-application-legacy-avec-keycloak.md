---
author: Simon
title: Comment faire évoluer une application legacy sans exploser mon budget ?
categories: legacy keycloak migration oidc oauh2 sso ldap java angular authentification
---

Comment faire évoluer une application legacy sans exploser mon budget et attendre de nombreux mois voir plus d'une année pour voir mes évolutions ? Comment ne pas tout refaire d’un coup et apporter de la valeur rapidement ?

- [Introduction](#introduction)
- [Mise en place du service d'authentification SSO](#mise-en-place-sso)
    - [1ère étape : intégration du service d'authentification à l'application existante](#integration-legacy)
    - [2ème étape : provisionnement des utilisateurs dans le service d'authentification](#provisionnement-utilisateurs)
    - [3ème étape : configuration du nouveau service](#configuration-nouveau-service)
- [Conclusion](#conclusion)

## Introduction <a class="anchor" name="introduction"></a>

Nous devions faire évoluer une application du service publique réalisée avec des **technologies  obsolètes** (framework et dépendances non mis à jour, nombreuses CVE) pour y ajouter de **nouvelles fonctionnalités**. Pour des raisons de priorité et de moyens, il a été décidé de ne pas tout refaire en premier lieu. Cette application est server-side : la génération des pages est réalisée côté serveur.

![Architecture initiale](/assets/images/migrer-application-legacy-avec-keycloak/architecture-V1.drawio.png)
*Architecture initiale*

Nous avons choisi de réaliser les nouvelles fonctionnalités dans un **socle technique plus pérenne.** Il y aura donc 2 applications et il faudra passer de l'une à l'autre de manière transparente afin de maintenir la **simplicité de navigation** pour un utilisateur. Il nous fallait donc mettre en place un **service d'authentification SSO** pour avoir à se connecter qu'une seule fois et faire en sorte d'avoir la même charte graphique sur la nouvelle application. Cette nouvelle application sera client-side : les pages seront crées côté client et les requêtes seront envoyées sur le serveur quand cela sera nécessaire.

![Architecture cible avec serveur SSO](/assets/images/migrer-application-legacy-avec-keycloak/architecture-V2.drawio.png)
*Architecture cible avec serveur SSO*

Cette stratégie permettra de basculer les fonctionnalités déjà réalisées dans la nouvelle application à terme.

## Mise en place du service d'authentification SSO <a class="anchor" name="mise-en-place-sso"></a>

Nous avons choisi d'utiliser la solution **Keycloak Server**, un serveur de gestion des identités et des accès open source qui permet de gérer **l'authentification unique** avec plusieurs protocoles (OpenID Connect, OAuth 2.0 et SAML2.0). Il prend en charge la connexion à des annuaires externes type LDAP ou Active Directory. Nous allons créer un **domaine** (ou royaume) pour définir l'ensemble des utilisateurs, leurs rôles et les applications auxquels ils auront accès.

![Ajouter un domaine](/assets/images/migrer-application-legacy-avec-keycloak/domaine.png)
*Ajouter un domaine*

Nous choisirons le protocole **OpenID Connect** pour l'ensemble des clients définit par la suite. 
L'application existante fournit son propre système authentification : 
- un **formulaire** sur la page d'accueil permet à l'utilisateur de saisir son adresse mail ainsi que son mot de passe
- un mécanisme de **session HTTP** maintient les données de l'utilisateur connecté côté serveur
- une partie **gestion des utilisateurs** permet aux administrateurs de créer et modifier des utilisateurs et de changer leurs permissions

### 1ère étape : intégration du service d'authentification à l'application existante <a class="anchor" name="integration-legacy"></a>

Pour migrer le système d'authentification dans Keycloak, nous allons commencer par créer le  client dans le domaine :

![Création du client legacy](/assets/images/migrer-application-legacy-avec-keycloak/create-legacy.png)
*Création du client legacy*

Nous le laissons Actif avec le flow Standard, désactivons "Direct access grants enabled" qui ne sera pas utile dans notre cas, saisissons les URLs de redirections valides et choisissons l'Access Type **confidential** :  c'est le type à utiliser pour les applications server-side. Il permet d'autoriser seulement l'application à initier la demande de login pour le client ID donné. Cela nécessite un secret partagé entre le serveur d'authentification et l'application non visible par les utilisateurs (OAuth2).

Côté application, si l'utilisateur souhaite se connecter (bouton Se Connecter) il sera redirigé vers l'**interface d'authentification du domaine** (Keycloak). Pour mettre en œuvre OIDC, nous aurons besoin de nouveaux endpoints sur l'ancienne application :
- `/callback` : il devra aller récupérer l'identité de l'utilisateur connecté et nous permettra d'initier la session utilisateur par défaut ou bien de la supprimer si le paramètre logoutendpoint est renseigné
- `/logout` : il déconnectera l'utilisateur de Keycloak

Un framework de sécurité était déjà en place : **Shiro qui permet de contrôler l'authentification et les autorisations**. Pour compléter ce framework et proposer ces endpoints, nous utilisons la **bibliothèque pac4j**.

À présent, il faut activer "**Backchannel Logout Session Required**" dans la configuration du client pour indiquer au service Keycloak d'appeler une URL pour invalider la session de l'utilisateur. Cette URL est à renseigner dans "Backchannel Logout URL" : 

```
http://<client-host>/callback?logoutendpoint=true
```

### 2ème étape : provisionnement des utilisateurs dans le service d'authentification <a class="anchor" name="provisionnement-utilisateurs"></a>

À présent, le service d'authentification vérifie l'accès aux utilisateurs (email et mot de passe) depuis sa base de données. Il faut donc adapter la gestion utilisateurs existante pour que la base de données soit provisionnée sur l'**ajout d'un utilisateur** et supprimer l'**authentification** et la modification du mot de passe. Pour cela, nous utilisons l'**API Admin de Keycloak**.
Le client Keycloak "service-public.legacy" doit avoir avoir accès aux API d'Admin et avoir les rôles de gestion des utilisateurs. Nous devons donc activer "Service Accounts Enabled" dans la configuration Keycloak du client. 

![Activation du Service Accounts](/assets/images/migrer-application-legacy-avec-keycloak/service-account-enabled.png)
*Activation du Service Accounts*

Puis, il faut assigner les rôles "manage-users", "view-authorization", "view-users"  du client "realm-management" dans la partie "Service Account Roles" :

![Rôles à assigner](/assets/images/migrer-application-legacy-avec-keycloak/service-account-roles.png)
*Rôles à assigner*

Keycloak fournit une bibliothèque Java pour utiliser son API : **keycloak-admin-client** dans la même version que celle du service pour garantir la compatibilité.

```xml
<dependency>
 <groupId>org.keycloak</groupId>
 <artifactId>keycloak-admin-client</artifactId>
 <version>18.0.0</version>
</dependency>
```

Voici la configuration nécessaire pour utiliser l’API :

```java
Keycloack keycloak = KeycloakBuilder.builder()
   .serverUrl(<serveur Keycloak>)
   .realm("service-public.usagers")
   .grantType(CLIENT_CREDENTIALS)
   .clientId("service-public.legacy")
   .clientSecret(<secret du projet legacy>)
   .build();
```

Nous pourrons alors créer les utilisateurs depuis l’ancienne application avec le code suivant :

```java
try (Response response = keycloak
        .realm("service-public.usagers")
        .users()
        .create(buildUserRepresentation(user))) {
    if ( !response.getStatusInfo().getFamily().equals(Response.Status.Family.SUCCESSFUL)) {
        throw new Exception(response.getStatusInfo().getReasonPhrase());
    }
}
```

La documentation est accessible ici : 
[https://www.keycloak.org/docs-api/18.0/javadocs/org/keycloak/admin/client/KeycloakBuilder.html](https://www.keycloak.org/docs-api/18.0/javadocs/org/keycloak/admin/client/KeycloakBuilder.html)

### 3ème étape : configuration du nouveau service <a class="anchor" name="configuration-nouveau-service"></a>

Le point d’entrée de l’application se fera sur le nouveau service. Il est composé d’une partie frontend : l’application web et d’une partie backend : l’API. Pour la partie frontend, nous devrons déclarer un nouveau client dans le même domaine Keycloak :

![Création du nouveau client](/assets/images/migrer-application-legacy-avec-keycloak/create-nouveau.png)
*Création du nouveau client*

Nous le laissons Actif avec le flow Standard, désactivons « Direct access grants enabled » qui ne sera pas utile dans notre cas, saisissons les URLs de redirections valides et choisissons l’Access Type public: c’est le type à utiliser pour les applications client-side. Il n’est pas utile de partager un secret car il serait vu par l’utilisateur (embarqué dans l’application téléchargée). N’importe quelle application qui a une URL validée (Valid redirect URI) pourra initier la demande de login.

Cette nouvelle application est réalisée avec le framework Angular. Nous utilisons donc la dépendance keycloak-angular ([https://github.com/mauriciovigolo/keycloak-angular](https://github.com/mauriciovigolo/keycloak-angular)) qui nous permet de s’interfacer simplement avec le service. Nous utilisons la configuration suivante :

```json
{
    "config": {
        "url": "<serveur Keycloak>/auth",
        "realm": "service-public.usagers",
        "clientId": "service-public.nouveau"
    },
    "initOptions": {
        "onLoad": "check-sso"
    }
}
```



## Conlusion <a class="anchor" name="conclusion"></a>

Depuis que cette solution est mise en œuvre, l’ajout de nouvelles fonctionnalités s’est fait de manière beaucoup plus sereine et nous avons pu migrer certaines anciennes fonctionnalités au fil de l’eau dès qu’il y avait besoin de les faire évoluer.

La gestion des utilisateurs a pu être également complètement revue dans un module séparé sans impacter le système existant.

Le service Keycloak a eu un rôle crucial dans cette mise en œuvre, nous nous sommes rendu compte à quel point le service était complet et adaptable selon les besoins avec un haut niveau de customisation.

Enfin, cette réalisation confirme l’importance de décomposer son architecture en plusieurs services avec une utilité spécifique afin de limiter les impacts lors d’évolutions ou de migrations.