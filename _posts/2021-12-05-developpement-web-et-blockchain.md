---
author: Gwenolé
title: Introduction à la blockchain
categories: blockchain
---


Nous parlerons ici de ce qu'est la blockchain et comment elle peut amener une nouvelle façon de penser le développement applicatif.

- [Introduction](#introduction)
- [La blockchain, kézako ?](#kesaco)
    - [les blocs](#bloc)
    - [les nœuds](#nœud)
    - [sécurité et transparence](#avantages)
- [Exemple d'implémentation de la blockchain](#examples)
    - [Validation de transaction](#transaction)
    - [Les contrats intelligents](#contract)
    - [L'authentification](#identification)
    - [La propriété virtuelle](#properties)
- [Conclusion](#conclusion)

## Introduction <a class="anchor" name="introduction"></a>

Vous avez sans doute entendu parler des blockchains si vous vous êtes intéressés aux cryptomonnaies.

Nous allons d'abord expliquer ici ce qu'est une blockchain, puis nous allons montrer des exemples concrets d'implémentation de blockchains dans le développement applicatif.

## La blockchain, kézako ? <a class="anchor" name="kesaco"></a>

La blockchain est une technologie de stockage et de transmission d'informations de manière décentralisée.

Dans une application web classique, le stockage et la transmission des informations sont gérés par une partie serveur, elle-même gérée par la société gérant l'application ou par un tiers travaillant pour celle-ci. Dans ce type de système, l'information est centralisée, car seul le ou les intermédiaires gérant l'application ont une vision et un contrôle global sur les informations.
On est donc dépendant de cet intermédiaire pour notamment la sécurité et la visibilité de celle-ci.

La blockchain ne passe plus par un tiers pour cela mais par des nœuds. Ces nœuds partagent les mêmes informations dans ce que l'on appelle des blocs.

Nous allons voir maintenant plus en détails les notions de bloc et de nœud et expliquer les avantages qu'elles apportent.

### les nœuds <a class="anchor" name="nœud"></a>

Dans une blockchain, nous avons un réseau de nœuds - qui peuvent être n'importe quel type de support électronique - qui partage les informations.
Lors d'une transmission de données par exemple, celles-ci ne seront pas diffusées à un serveur mais à un ensemble de nœuds qui les enregistreront et qui pourront transmettre ces données à leur tour. Cela rend la falsification d'informations plus difficile, car en attaquant un nœud et en changeant les informations y étant contenu, les autres nœuds pourront invalider celles-ci en les comparant à leurs propres données, et l'on ne consulte jamais un seul nœud.

Voici un exemple de transmission d'informations avec l'un des nœuds corrompus :

![transmission informations](/assets/images/blockchain/blockchain-1.svg)


### les blocs <a class="anchor" name="bloc"></a>

Dans une blockchain, les informations sont stockées sous forme de blocs chaînés. Un bloc possède de la donnée et un bloc parent. C'est grâce à ce parent que l'on peut assurer la non-altération des données.

En effet les blocs ayant un ordre défini, il est impossible d'insérer de fausses transactions par exemple dans un bloc, car en comparant ce bloc avec le bloc ayant le même parent dans les autres nœuds, il n'y aura pas de correspondance.

Voici un schéma de la validation d'un bloc représentant 3 nœuds avec la même chaîne de blocs mais avec un bloc frauduleux qui s'est inséré dans l'un des nœuds : 

![validation bloc](/assets/images/blockchain/blockchain-2.svg)

On peut aisément identifier le bloc inséré dans le nœud corrompu en comparant les parents de chaque bloc. Le nœud 1 et 3 ont le bloc 1 comme parent du bloc 2 alors que le nœud 2 possède le bloc frauduleux en parent du bloc 2.

### Sécurité et transparence <a class="anchor" name="avantages"></a>

La blockchain permet donc une meilleure protection contre l'altération des informations du réseau, mais aussi une plus grande transparence.
En effet les informations étant partagées par un ensemble de nœuds, aucun intermédiaire n'est requis, et donc aucune action de filtrage de l'information n'est possible. Cela pourrait permettre par exemple un meilleur suivi des transactions de marchandises qui peuvent avoir de nombreux intermédiaires avant le consommateur final, donc plus de difficulté pour tracer la provenance des produits.

Attention cependant, une blockchain n'est pas exempte de toute faille. Une attaque connue est celle des 51%, qui consiste à posséder plus de la moitié de la capacité de validation pour pouvoir valider des transactions corrompues. Ce genre d'attaque est difficilement envisageable maintenant sur les principales blockchains, celles-ci ayant un réseau de nœuds trop important pour que l'on puisse posséder plus de la moitié des nœuds, mais les nouveaux réseaux de blockchain y sont exposés si aucune sécurité supplémentaire n'est mise en place.

## Exemple d'implémentation de la blockchain <a class="anchor" name="examples"></a>

Nous allons voir ici quelques exemples déjà bien éprouvés d'utilisation de la blockchain dans le monde du web.

### Validation de transaction <a class="anchor" name="transaction"></a>

La transparence, la sécurité et l'absence d'intermédiaire pour les transactions ont permis de développer ce que l'on appelle la finance décentralisée (**DeFi**).

La **DeFi** permet de faire des achats, ventes, prêts, contrats, transferts d'argent etc... sur une blockchain. Ainsi la liste des opérations est connue de tous les nœuds (transparence des transactions) et devient donc non-altérable.

Nous ne citerons pas ici d'exemple de plateforme de **DeFi**, mais sachez qu'il en existe une multitude, chacune avec ses avantages et ses inconvénients (frais de transactions, choix des cryptomonnaies utilisables, rendement etc...).

### Les contrats intelligents <a class="anchor" name="contract"></a>

Un contrat intelligent - smart contract en anglais - définit les règles d'un accord entre plusieurs parties et enregistre ces règles dans la blockchain.

Par exemple dans la **DeFi**, un contrat intelligent permet de figer les règles du contrat dans une blockchain tout en assurant le transfert d’un actif – quel qu’il soit, le virement d'une cryptomonnaie en tant que rendement d'un investissement par exemple – lorsque les conditions contractuelles se vérifient.

Il faut par contre faire bien attention aux contrats que vous acceptez, certaines arnaques sur la blockchain consistent à vous faire accepter un contrat qui accepte le transfert de vos cryptomonnaies vers un compte appartenant aux arnaqueurs.

### L'identification <a class="anchor" name="identification"></a>

Si la blockchain est assez sécurisée et transparente pour la **DeFi**, alors elle s'adapte tout aussi bien aux problématiques d'identification.

En effet l'absence d'entité centrale de vérification et l'impossibilité de falsifier les données des blocs permet de garantir l'identité d'une entité.

Cela peut servir pour empêcher l'usurpation d'identité, comme le permet [Civic](https://www.civic.com/) par exemple, une plateforme qui permet aux utilisateurs d'enregistrer et de valider leurs informations personnelles d'identité et de verrouiller leur identité afin d'en empêcher le vol et les activités frauduleuses.

Cela permet également de lutter contre la contrefaçon de produits, chacun étant identifié sur la blockchain son authenticité peut être vérifiée. **AWS** a d'ailleurs déjà mise en place [un outil basé sur la blockchain](https://aws.amazon.com/blockchain/blockchain-for-supply-chain-track-and-trace/) pour cette problématique.

### La propriété virtuelle <a class="anchor" name="properties"></a>

Si vous suivez de près ou de loin le monde de la blockchain, le terme NFT (pour "Non Fungible Token" ou en français "Jeton Non Fongible") ne doit pas vous être étrangé.

Un NFT est un token numérique sur la blockchain qui possède des caractéristiques propres et qui est unique et non reproductible (cela est garantie par la blockchain).

Le principe du NFT a déjà connu diverses utilisations, comme par exemple :
- des oeuvres numériques dont la propriété est enregistrée sur la blockchain. Cela peut être une peinture numérique comme un album par exemple.
- des objets virtuels dans des univers virtuels. Si vous avez entendu parler des metaverses ou bien métavers en français, terme qui désigne un univers virtuel parallèle dans le cas présent, les NFT y jouent un rôle important car chaque objet que vous pouvez y posséder peut être un NFT, ce qui garantit son unicité mais également sa valeur (il peut y avoir un nombre limité de NFT partageant les mêmes caractéristiques par exemple).
- la correspondance avec des objets réels. Ainsi lors de l'achat d'un objet réel, vous pouvez valider la transaction sur la blockchain et ainsi avoir la preuve numérique de sa propriété.

## Conclusion <a class="anchor" name="conclusion"></a>

La blockchain est sans doute l'une des technologies les plus marquantes de ces dernières années, et nous ne sommes sans doute qu'aux prémices des changements que cela apportera à l'avenir.

Beaucoup d'institutions et d'investisseurs commencent à s'y intéresser maintenant que la technologie a pu faire ses preuves, et l'engouement pour les nouvelles opportunités que la blockchain permet ne cesse de croître.

Pour s'en convaincre, il suffit de regarder la levée de fond de la société [Sorare](https://sorare.com/), qui lance un jeu de cartes de joueurs de football à collectionner sous forme de NFT, qui s'est élevée à 680 millions d'euros, rien que ça.

Malgré un bel avenir, les réseaux blockchains peuvent également avoir un impact énergétique important, notamment via la méthode de validation par *Proof Of Work* qui nécessite une forte puissance de calcul. D'autres méthodes de validation ont depuis fait leur apparition pour diminuer cet impact (e.g *Proof Of Stake*), ainsi que des méthodes pour réutiliser cette consommation énergétique (des calculateurs qui servent également de chauffage par exemple).

Un autre problème est la saturation du réseau : l'utilisation de plus en plus importante de la blockchain et la limitation du nombre de transactions par seconde entraîne une augmentation du coût de validation des transactions.