---
author: Marc
title: Dynamiser vos pipelines Gitlab-CI
categories: [gitlab,ci-cd,pipelines,nestjs]
---
Votre fichier `.gitlab-ci.yml` commence à être très long, et les jobs se ressemblent étrangement ? C'est qu'il est temps de rendre votre pipeline dynamique ! Exemple avec un projet NestJS.

- [Explications](#explications)
- [Cas d'usages](#cas-dusages)
- [Exemple avec un monorepo NestJS](#exemple-avec-un-monorepo-nestjs)

# Explications

Les pipelines dynamiques, aussi appelés "Downstream pipelines" ont été introduit dans Gitlab en version 12.7. Ce n'est pas quelque chose de très récent, mais nous n'avons pas l'habitude d'en voir souvent.

Ces pipelines peuvent être de 2 types :
- Pipeline Parent/Enfant
- Pipeline multi-project

Ici nous parlerons du type Parent/enfant (**parent-child pipeline**), mais sachez que l'autre type existe.

Pour résumer la [documentation](https://docs.gitlab.com/ee/ci/pipelines/downstream_pipelines.html) de Gitlab, un downstream pipeline de type Parent/Enfant, est un pipeline enfant qui se déroule dans le même projet que le pipeline parent. Ce pipeline peut affecter le statut du pipeline parent selon la stratégie qui lui est appliquée (ex: `strategy: depend`).

Un downstream pipeline est déclenché par un job parent avec le mot clé `trigger`. Ce job doit fournir une configuration d'un pipeline, sous la forme d'un fichier `yaml`. Ce fichier peut être statique, mais aussi **dynamique** et fourni en tant qu'artifact du job parent. Il faut donc au minimum 2 jobs : celui qui produit la configuration, et un autre qu'il l'interprète.

Voici un exemple de présentation de l'interface avec un downstream pipeline : 

![downstream pipeline](/assets/images/gitlab/downstream-pipelines.png)

# Cas d'usage

Certains projets vont être plus propices à ce type de pipeline, c'est le cas par exemple des workspaces en monorepo (comportant plusieurs applications, librairies, etc.) qui contiennent généralement un fichier de configuration global au projet (exemple en NestJS ci-après).
Les projets dont les livrables peuvent être déclinés (marque blanche, environnement) sont également concernés. 

Dans ces cas, les **downstream pipelines** vont être avantageux pour plusieurs raisons : 

- Evite d'ajouter une nouvelle configuration pour un nouveau module/composant, donc gain de temps sur la partie CI. 
- Evite des copier/coller hasardeux de configuration de job. 
- Réduit la taille de la configuration Gitlab-CI, qui devient donc plus maintenable.



# Exemple avec un monorepo NestJS

Voyons comment le mettre en place sur un projet NestJS. Ce projet se présente sous forme d'un monorepo et comporte un fichier de configuration `nest-cli.json` décrivant la liste des applications et librairies du workspace. 

```js
const { writeFileSync, readFileSync } = require('fs');

// Fonction de création d'un job de build pour un projet donné
 const createJob = (project) => `
${project}:build:
  stage: build
  image: node:18-alpine
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - ./.npm
    policy: pull
  before_script:
    - npm ci --cache .npm --prefer-offline
  rules:
    - if: $CI_PIPELINE_SOURCE == "parent_pipeline"
  script:
    - npm run build ${project}
`;
 
const createDynamicGitLabFile = () => {
    const nestCliConf = readFileSync('./nest-cli.json');
    const projectsConfigurations = JSON.parse(nestCliConf);
    // Lecture des clés de la structure "projects" qui représentent les noms de projet
    const pipeline = Object.keys(projectsConfigurations.projects)
        .map(createJob)
        .join('');

    writeFileSync('dynamic-build-gitlab-ci.yml', pipeline);
};

createDynamicGitLabFile();
```

Ce script **nodejs** vient lire le fichier de configuration NestJS et génère un fichier de configuration avec l'ensemble des jobs nécessaires.

Il peut être appliqué dans un job très simple : 

```yaml
apps:build:generate:
  stage: build
  script:
    - node ./create-build-pipeline.js
  artifacts:
    paths:
      - dynamic-build-gitlab-ci.yml # fichier généré par le script
```

Ensuite le fichier généré va être interprété par un job avec le mot clé `trigger` :

```yaml
apps:build:pipeline:
  stage: build
  needs:
    - apps:build:generate
  trigger:
    include:
      - artifact: dynamic-build-gitlab-ci.yml
        job: apps:build:generate # nom du job parent
    strategy: depend # indique que l'état du pipeline influe sur le pipeline parent 
```

Enfin l'ensemble du pipeline enfant peut être visible en cliquant sur le downstream job :

![downstream pipeline_children](/assets/images/gitlab/downstream-pipelines-2.png)

