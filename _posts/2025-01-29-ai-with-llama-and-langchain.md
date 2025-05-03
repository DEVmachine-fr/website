---
author: Gwenolé
title: Comment faire tourner une IA en local avec langchain, Llama, Nodejs et Vue3
categories: langchain vue3 node llama ollama
---

Nous partageons ici un tutoriel pour faire fonctionner simplement une **intelligence artificielle** avec **langchain**, **Llama**/**Deepseek**, **Node.js** et **Vue 3**.

- [Introduction](#introduction)
- [Installation](#installation)
  - [Création d'un environnement virtuel python](#python)
  - [Installation du modèle d'IA](#ia)
    - [Installation d'Ollama](#ollama)
    - [Installation de Llama](#llama)
    - [Installation de Deepseek](#deepseek)
- [Création du chat](#chat)
  - [Mise en place du serveur Node](#node)
  - [Mise en place du client Vue3](#vue3)
- [Ressources](#ressources)

## Introduction <a class="anchor" name="introduction"></a>

Ce tutoriel a pour but de voir comment l'on peut assez facilement implémenter une **intelligence artificielle** dans nos projets. On prendra ici **Vue3** pour la partie client et **Nodejs** pour la partie serveur, mais ce tutoriel peut assez simplement être adapté à d'autres outils (surtout pour la partie client si vous utilisez également **javascript** ou **typescript**).

Nous n'aborderons pas ici l'enrichissement du contexte ou bien l'amélioration du **LLM** (Large Language Model, votre modèle d'IA en résumé).

## Installation <a class="anchor" name="installation"></a>

### Création d'un environnement virtuel python <a class="anchor" name="python"></a>

Pour pouvoir faire tourner Llama, il nous faudra tout d'abord un environnement avec Python 3.10 d'installé. Pour cela nous allons créer un environnement virtuel. Les étapes qui suivent sont les étapes à suivre si vous êtes sur Ubuntu mais seront assez semblables sur d'autres distributions.

- Commençons par mettre à jour les packages disponibles pour notre distribution avec `sudo apt update`.
- Vous pouvez lancer `sudo apt upgrade` pour mettre à jour tous les packages ou seulement mettre à jour le package python.
- Vous pouvez vérifier la version de python3 via `python3 --version`.
- Si la version de **python3** est toujours inférieure à 3.10 après la mise à jour (ou si vous avez eu une erreur en voulant faire la mise à jour manuellement pour ce package), alors il vous faudra ajouter le répertoire "Deadsnakes" aux répertoires de packages de votre distribution. Pour cela:
  - Il nous faut d'abord pouvoir ajouter un répertoire via la commande **add-apt-repository**. Pour cela une autre installation s'impose: `sudo apt install software-properties-common -y`.
  - Ensuite on ajoute le répertoire "Deadsnakes": `sudo add-apt-repository ppa:deadsnakes/ppa`.
  - On refait une mise à jour des packages disponibles: `sudo apt update -y`.
  - On installe **python3.10**: `sudo apt install python3.10 -y`.
- Naviguez ensuite dans le dossier dans lequel vous souhaitez créer votre environnement virtuel et lancez la commande : `python3.10 -m venv ./`.

### Installation du modèle d'IA <a class="anchor " name="ia"></a>

#### Installation d'Ollama <a class="anchor" name="ollama"></a>

Nous allons installer Ollama qui simplifie le déploiement et la gestion des modèles.
Ollama permet de télécharger et d'éxécuter un nombre important de modèle LLM, notamment les LLM Llama et Deepseek que nous détaillerons dans ce tutoriel.
Ollama permet également de créer son propre modèle mais cette fonctionnalité ne sera pas abordée dans ce tutoriel.

Nous allons activer notre environnement virtuel puis télécharger le modèle:

- À la racine du dossier de votre environnement virtuel lancez la commande: `source bin/activate`.
- Installez Ollama: `curl -fsSL https://ollama.com/install.sh | sh`.

#### Installation de Llama <a class="anchor" name="llama"></a>

Nous utiliserons dans notre cas la version Llama 3.2 lightweight 1B:
- Téléchargez et lancez la version Llama qui correspond à votre demande sur le site de [Llama](https://www.llama.com/): `ollama run llama3.2:1b` dans notre exemple. Le modèle sera lancé par défaut sur `localhost:11434`.

Nous avons maintenant notre modèle Llama opérationnel dans notre environnement virtuel, nous pouvons désormais créer notre chat et le connecter à notre modèle.

#### Installation de Deepseek <a class="anchor" name="deepseek"></a>

Pour utiliser Deepseek, c'est encore plus simple ! Pas besoin de faire de demande de téléchargement ici, lancez simplement **ollama** avec la version **Deepseek** que vous souhaitez. Attention tout de même, la version lightweight de **Deepseek** est plus conséquente que celle d'Ollama (pour notre version **deepseek-v2:lite** il vous faudra compter 8,9Gb par exemple): `ollama run deepseek-v2:lite`

## Création du chat <a class="anchor" name="chat"></a>

### Mise en place du serveur Node <a class="anchor" name="node"></a>

**Si vous faites ce tutoriel en plusieurs fois, pensez bien à réactiver votre environnement virtuel !**

On pourrait directement brancher notre client avec Ollama, mais il est intéressant d'avoir un serveur node pour implémenter par la suite un contexte côté API pour enrichir les réponses de notre IA.

Créez un répertoire pour votre serveur Node. Nous l'appellerons dans ce tutoriel **node-server** tout simplement.

Initiez un projet dans ce répertoire:
{% include code-header.html %}
```sh
npm init
```

Installons ensuite les dépendances Ollama et langchain dont nous aurons besoin:
{% include code-header.html %}
```sh
npm i --save langchain @langchain/core @langchain/ollama
```

Nous allons également utiliser express:
{% include code-header.html %}
```sh
npm i --save express
```

Pour faciliter la communication, nous allons installer **cors**:
{% include code-header.html %}
```sh
npm i --save cors
```

Créons le fichier **ai-model.js** dans lequel nous aurons le fonctionnement pour requêter le service **Ollama**:
{% include code-header.html %}
```js
import { Ollama } from "@langchain/ollama";

export class AI {
  aiModel;
  // remplacer llama3.2:1b par votre modèle, deepseek-v2:lite dans notre exemple avec Deepseek
  constructor(model = "llama3.2:1b", baseUrl = "localhost:11434") {
    this.aiModel = new Ollama({ model, baseUrl });
  }
  async chatMessage(req, res) {
    try {
      // On récupère ici le message de l'utilisateur envoyé par le client
      const message = req.body.message;
      // La réponse complète d'une IA peut être streamée pour éviter un trop long temps d'attente
      // On pourra ainsi afficher côté client la réponse de l'IA au fur et à mesure de sa complétion
      const responseStream = await this.aiModel.stream(message);
      // Pour chaque morceau de réponse reçu, on écrit ce morceau
      for await (const chunk of responseStream) {
        res.write(chunk);
      }
      // Lorsque la réponse est complète, on met fin à la requête
      res.end();
    } catch (error) {
      console.error("error: ", error);
      res.status(500).json({ error: error.message }).send();
    }
  }
}
```

Ensuite dans le fichier **index.js** déjà créé à l'initialisation, nous allons créer une route pour appeler notre fonction **chatMessage**:
{% include code-header.html %}
```js
import { AI } from "./aa-model.js";
import cors from "cors";
import express from "express";

const app = express();
app.use(cors());
const port = 3000;
const aiModel = new AI();

app.get("/", (req, res) => {
  res.send("Node server is running");
});

app.post("/message", (req, res) => {
  return aiModel.chatMessage(req, res);
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
```

Attention cependant à ne pas laisser les **CORS** sans restriction après vos tests !

### Mise en place du client Vue3 <a class="anchor" name="vue3"></a>

**Si vous faites ce tutoriel en plusieurs fois, pensez bien à réactiver votre environnement virtuel !**

Nous allons ici utiliser **Vue3** avec la **composition API**.

Tout d'abord commençons par installer le projet **Vue3** qu'on nommera vue-client (je vous laisse choisir les options que vous souhaitez pour le projet, mais nous continuerons le tutoriel en **typescript**, et on utilisera pas le routing puisque l'on aura une seule page):
{% include code-header.html %}
```sh
npm create vue@latest
```

Nous allons aussi installer **marker** qui nous permettra de transformer les réponses **markdown** en **html**:
{% include code-header.html %}
```sh
npm i --save marker
```

on suit ensuite les instructions pour tester l'installation:
{% include code-header.html %}
```sh
npm i
npm run format
npm run dev
```

Allez ensuite sur l'url affiché dans la console pour vérifier que vous avez bien accès au client.

On supprime les composants existants et on crée notre composant **Chatbot.vue**.

On va tout d'abord modifier le fichier de style **main.css** comme ceci:
{% include code-header.html %}
```css
@import "./base.css";

html,
body,
#app {
  width: 100%;
  min-height: 100vh;
  margin: 0;
}
```

On commence par créer le template avec une zone pour l'affichage de la discussion et une zone de saisie de texte, avec les couleurs de **DEV machine** bien évidemment:
{% include code-header.html %}
```vue
<template>
  <div class="chatbot">
    <div class="chat-history-container" ref="chat-history"></div>
    <div class="chat-input">
      <input type="text" />
      <button type="submit">send</button>
    </div>
  </div>
</template>

<style scoped>
.chatbot {
  background-color: #243252;
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  min-height: 100vh;
  align-items: center;
  justify-content: start;
}
.chat-input {
  width: 100%;
  margin-top: auto;
  display: flex;
  flex-direction: row;
  align-items: center;
  padding: 20px;
}
input {
  box-shadow: none;
  border: none;
  background-color: white;
  color: #243252;
  height: 30px;
  border-radius: 15px;
  padding: 10px;
  box-sizing: border-box;
  width: 100%;
  flex: 1;
  margin-right: 20px;
}
button {
  cursor: pointer;
  border: none;
  margin-left: auto;
  height: 30px;
  border-radius: 15px;
  padding: 0 10px;
  text-transform: uppercase;
  font-weight: bold;
  color: white;
  background-color: #fc766a;
}
</style>
```

On change ensuite le **App.vue** générée lors de la création du projet pour implémenter le composant **Chatbot.vue**:
{% include code-header.html %}
```vue
<script setup lang="ts">
import Chatbot from "./components/Chatbot.vue";
</script>

<template>
  <div class="app">
    <Chatbot />
  </div>
</template>

<style scoped>
.app {
  min-height: 100vh;
  width: 100%;
  margin: 0;
}
</style>
```

Vous devriez obtenir ceci:

![Visualisation App.vue](/assets/images/chatbot-ollama/app-vue.png)

On retourne maintenant compléter **Chatbot.vue**.

On va créer le script avec en variables:

- **apiUrl**: l'url du serveur node
- **apiPort**: le port du serveur node
- **userInput**: la saisie utilisateur (variable réactive)
- **currentIAResponse**: la réponse en cours de notre IA (variable réactive)
- **chatHistory**: l'historique de la discussion (variable réactive)

La variable **chatHistory** sera un tableau d'objet avec deux propriétés: -**sender**: permettra de déterminer si le message vient de l'utilisateur ou de l'IA -**message**: le message associé à cette entrée dans le chat

Nous allons initialiser **chatHistory** avec un premier message de l'IA également.

Nous allons également créer une fonction **sendMessage** qui dans un premier temps se contentera d'ajouter le message de l'utilisateur dans **chatHistory** (la fonction est asynchrone pour la suite de l'implémentation).

On aura donc pour le moment comme script ceci:
{% include code-header.html %}
```vue
<script setup lang="ts">
import { marked } from 'marked'
import { ref } from "vue";

const apiUrl = "localhost";
const apiPort = 3000;
// Saisie utilisateur
const userInput = ref("");
// Réponse en cours de l'IA
const currentIAResponse = ref("");
// Historique des messages déjà échangés
// On initialise un premier message de l'IA
const chatHistory = ref([
  {
    sender: "AI",
    message: "Hello, How can i help you ?",
  },
]);
// Fonction pour envoyer le message utilisateur
// On se contente pour le moment de l'ajouter dans l'historique pour l'affichage
async function sendMessage() {
  const message = userInput.value
  if (!message) return
  userInput.value = ''
  chatHistory.value.push({ sender: 'User', message})
}
</script>
```

Nous complètons maintenant le template pour afficher **chatHistory** et **currentIAResponse** (même si ce dernier n'est pas encore modifié pour le moment) et ajouter une classe en fonction de l'expéditeur:
{% include code-header.html %}
```vue
<template>
  <div class="chatbot">
    <div class="chat-history-container" ref="chat-history">
      <template v-for="chatResponse in chatHistory" :key="`chat-message-${index}`">
        <div
          class="response"
          :class="{
            'user-response': chatResponse.sender === 'User',
            'ai-response': chatResponse.sender === 'AI',
          }"
          v-html="marked.parse(chatResponse.message)"
        ></div>
      </template>
      <div
        class="response ai-response"
        v-if="currentIAResponse"
        v-html="marked.parse(currentIAResponse)"
      ></div>
    </div>
    <div class="chat-input">
      <input type="text" v-model="userInput" @keyup.enter="sendMessage" />
      <button @click="sendMessage" type="submit">send</button>
    </div>
  </div>
</template>
```

On ajoute des styles sur ces nouvelles classes:
{% include code-header.html %}
```vue
<style scoped>
...
.chat-history-container {
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: start;
  padding: 15px;
  box-sizing: border-box;
}
.response {
  max-width: 95%;
  padding: 10px;
  border-radius: 15px;
  margin: 10px;
}
.user-response {
  margin-right: auto;
  background-color: white;
  color: #243252;
}
.ai-response {
  margin-left: auto;
  background-color: #fc766a;
  color: white;
}
</style>
```

Si vous retournez sur l'application et que vous tapez un message, vous devriez obtenir ce résultat:

![Interface client](/assets/images/chatbot-ollama/interface-client.png)

Complètons à présent la fonction **sendMessage** pour requêter notre serveur node et afficher la réponse de notre IA!
{% include code-header.html %}
```vue
<script setup lang="ts">
...
async function sendMessage() {
  const message = userInput.value
  if (!message) return
  userInput.value = ''
  chatHistory.value.push({ sender: 'User', message})
  const requestOptions = {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({message}),
  }
  // On envoie notre requête POST et on récupère un ReadableStream dans le body de la réponse
  const streamResponse = await fetch(`${apiUrl}:${apiPort}/message`, requestOptions)
  if (!streamResponse.body) return
  // Le ReadableStream nous renvoie simple des tableaux de nombres
  // On utilise TextDecoderStream pour transformer ces tableaux en chaînes de caractères
  // getReader nous permettra de lire la prochaine écriture faite dans la réponse côté serveur (res.write)
  const reader = streamResponse.body.pipeThrough(new TextDecoderStream()).getReader();
  // Booléen de condition pour l'arrêt de la lecture du stream
  let streamEnded = false
  // Texte de réponse partiel de l'IA que l'on a déjà récupéré
  let partialResponse = ''
  while (!streamEnded) {
    // On attend la lecture du prochain res.write côté serveur
    const { done, value } = await reader.read()
    // done est passé à true lorsque la réponse a été finalisé côté serveur (res.end)
    if (done) {
      streamEnded = true
    }
    // On ajoute le nouveau morceau de réponse au texte partiel
    partialResponse += value
    // Certains morceaux de réponse de l'IA ne sont composé que de quelques caractères
    // Pour éviter d'afficher des mots partiels dans la réponse courante, on ajoute des règles
    // 1: On ne tente une mise à jour que si l'on a plus de 5 caractères supplémentaire par rapport à la valeur déjà affiché
    // 2: On supprime tous les caractères après le dernier espace pour ne pas afficher des mots partiels
    if(partialResponse.length - currentIAResponse.value.length > 5) {
      currentIAResponse.value = partialResponse.substring(0, partialResponse.lastIndexOf(" "));
    }
  }
  // Une fois le stream terminé, on ajoute la réponse complète dans l'historique et l'on vide la réponse courante de l'IA
  chatHistory.value.push({ sender: 'AI', message: partialResponse })
  currentIAResponse.value = ''
}
...
</script>
```

Vous devriez maintenant pouvoir poser vos questions dans l'interface et voir votre IA vous répondre !

## Ressources <a class="anchor" name="ressources"></a>

[Site officiel de Llama](https://www.llama.com/)
[Site officiel d'Ollama](https://ollama.com/)
[Documentation javascript pour langchain](https://js.langchain.com/docs/introduction/)
[Documentation Nodejs](https://nodejs.org/docs/latest/api/)
[Documentation Vue3](https://vuejs.org/guide/introduction.html)
[Projet github du tutoriel](https://github.com/gerard-g-dm/langchain-ollama-vue-node)
