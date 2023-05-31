---
author: Marc
title: Dynamiser vos pipelines Gitlab-CI
categories: [gitlab,ci-cd,pipelines,nestjs]
---
Votre fichier `.gitlab-ci.yml` commence à être très long, et les jobs se ressemblent étrangement ? C'est qu'il est temps de rendre votre pipeline dynamique ! Exemple avec un projet NestJS.

- [Explications](#explications)
- [Exemple avec un monorepo NestJS](#exemple-avec-un-monorepo-nestjs)
- [Avantages](#avantages)

# Explications

Les pipelines dynamiques, aussi appelés "Downstream pipelines" ont été introduit dans Gitlab en version 12.7. Ce n'est pas quelque chose de très récent, mais nous n'avons pas l'habitude d'en voir souvent.

Ces pipelines peuvent être de 2 types :
- Pipeline Parent/Enfant
- Pipeline multi-project

Ici nous parlerons du type Parent/enfant (**parent-child pipeline**), mais sachez que l'autre type existe.

Pour résumer la [documentation](https://docs.gitlab.com/ee/ci/pipelines/downstream_pipelines.html) de Gitlab, un downstream pipeline de type Parent/Enfant, est un pipeline enfant qui se déroule dans le même projet que le pipeline parent. Ce pipeline peut affecter le statut du pipeline parent selon la stratégie qui lui est appliquée (`strategy: depend`).

Un downstream pipeline est déclenché par un job parent avec le mot clé `trigger`. Ce job doit fournir une configuration d'un pipeline, sous la forme d'un fichier `yaml`. Ce fichier peut être statique, mais aussi **dynamique** et fourni en tant qu'artifact du job parent. Il faut donc 2 jobs, un qui produit la configuration, et un autre qu'il l'interprète. Ce deuxième doit donc être dépendant du premier job.

Voici un exemple de présentation de l'interface avec un downstream pipeline : 

![downstream pipeline](/assets/images/gitlab/downstream-pipelines.png)


# Exemple avec un monorepo NestJS

Voyons comment le mettre en place sur un projet NestJS. Ce projet est sous forme d'un monorepo et comporte un fichier de configuration `nest-cli.json` contenant la liste des applications et librairies du workspace. 

```js
const { writeFileSync, readFileSync } = require('fs');

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
    const pipeline = Object.keys(projectsConfigurations.projects)
        .map(createJob)
        .join('');

    // write file to disc
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

Enfin le fichier généré va être interprété par un job avec le mot clé `trigger` :

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

L'ensemble du pipeline enfant peut être visible en cliquant sur le downstream job :

![downstream pipeline_children](/assets/images/gitlab/downstream-pipelines-2.png)


# Avantages

Pour certains cas d'usages, comme l'exemple ci-dessus en NestJS (mais aussi plus globalement sur des workspaces monorepo avec [Nx](https://nx.dev/)) ou encore des projets génériques, déclinables en marque blanche, ce type de pipeline semble avantageux pour plusieurs raisons. 

Cela nous évite d'ajouter une nouvelle configuration pour un nouveau module/composant, et donc bénéficions d'un gain de temps sur la partie CI. Cela permet aussi d'éviter des copier/coller hasardeux de configuration de job. Enfin la taille de la configuration Gitlab-CI devrait être fortement réduite, donc plus maintenable.

