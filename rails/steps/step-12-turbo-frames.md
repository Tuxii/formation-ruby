# Step 12 - Turbo Frames : modifier sur place

> **Départ** : la fin du step 11 (ou `origin/step-11`) · **Fichiers fournis** : aucun · **Solution** : `origin/step-12`

## Objectifs

- Voir ce que Turbo Drive fait depuis le début, sans que vous ayez écrit de JavaScript
- Découper une page en zones qui se mettent à jour seules, avec `turbo_frame_tag`
- Modifier un enregistrement sans quitter sa page
- Savoir sortir d'un frame

## 12.1 Turbo Drive est déjà là

Ouvrez les outils de développement du navigateur, onglet Réseau, filtre « Fetch/XHR ». Naviguez entre le catalogue, un atelier et une session : chaque clic est une requête `fetch`, la page n'est jamais rechargée en entier.

C'est Turbo Drive, installé par défaut (`app/javascript/application.js` importe `@hotwired/turbo-rails`) : il intercepte les clics sur les liens et les envois de formulaires, fait la requête lui-même, et remplace le `<body>` par celui de la réponse.

Conséquence pour les formulaires : dans `SessionsController#create`, retirez `status: :unprocessable_content` du `render :new`, puis programmez une session en laissant la date vide. Il ne se passe rien à l'écran, et la console du navigateur affiche `Form responses must redirect to another location`. Remettez le statut.

Après l'envoi d'un formulaire, Turbo attend une redirection (le succès) ou un statut d'erreur comme `422` (l'échec) pour afficher la réponse. C'est la raison des statuts que vous avez écrits au step 05.

> Doc : [Turbo Drive - Form Submissions](https://turbo.hotwired.dev/handbook/drive#form-submissions)

## 12.2 Modifier une session sur place

Pour changer la capacité d'une session, on quitte sa page, on modifie, on revient. On veut que le formulaire apparaisse **à la place** des informations, sans quitter la page.

Dans `app/views/sessions/show.html.erb`, entourez le titre, le badge et la liste `<dl>` d'un frame, et déplacez-y le lien « Modifier », qui était en bas de page :

```erb
<%= turbo_frame_tag "session_details" do %>
  <div class="d-flex align-items-center gap-3 mb-3">
    ...
  </div>

  <dl class="row">
    ...
  </dl>

  <%= link_to "Modifier", edit_session_path(@session), class: "btn btn-outline-secondary btn-sm" %>
<% end %>
```

Dans `app/views/sessions/edit.html.erb`, entourez le formulaire d'un frame **du même nom**, et remplacez le lien de retour par un lien « Annuler » placé dans le frame :

```erb
<%= turbo_frame_tag "session_details" do %>
  <%= render "form", session: @session %>

  <%= link_to "Annuler", @session, class: "btn btn-link px-0 mt-3" %>
<% end %>
```

Sur la page d'une session, cliquez sur « Modifier » : le formulaire prend la place des informations, le reste de la page ne bouge pas. Changez la capacité et enregistrez. Recommencez en vidant la date : l'erreur s'affiche sur place. « Annuler » ramène les informations.

Le contrôleur n'a pas changé. Un lien ou un formulaire placé **dans** un `<turbo-frame>` ne change pas de page : Turbo fait la requête, cherche dans la réponse un `<turbo-frame>` qui porte le même `id`, et remplace le contenu du frame par le sien. Le reste de la réponse est ignoré. Dans l'onglet Réseau, la requête porte un en-tête `Turbo-Frame: session_details`.

Le message « Session mise à jour. » ne s'affiche plus : il est rendu par le layout, hors du frame.

> Doc : [Turbo Frames](https://turbo.hotwired.dev/handbook/frames)

## 12.3 Sortir du frame

Dans le frame de `sessions/show.html.erb`, à côté de « Modifier », ajoutez un lien vers l'atelier :

```erb
<%= link_to "Voir l'atelier", @session.workshop, class: "btn btn-link btn-sm" %>
```

Cliquez : « Content missing ». La page de l'atelier ne contient pas de frame `session_details`, Turbo n'a rien à mettre à la place. Pour qu'un lien placé dans un frame change toute la page, ajoutez-lui :

```erb
data: { turbo_frame: "_top" }
```

Tout ce qui est dans un frame reste dans le frame, sauf indication contraire. C'est pour cela que le bouton « Supprimer » est resté en dehors.

> Doc : [Targeting Navigation Into or Out of a Frame](https://turbo.hotwired.dev/handbook/frames#targeting-navigation-into-or-out-of-a-frame)

## 12.4 À vous : un atelier sur place

**À vous.** Faites la même chose pour les ateliers, avec un frame `workshop_details` :

- dans `workshops/show.html.erb`, le frame entoure le titre, le badge, la durée, le nombre de participants et la description, avec le lien « Modifier » à l'intérieur
- dans `workshops/edit.html.erb`, le même frame entoure le formulaire, avec un lien « Annuler »

Vérifiez : modifiez le titre d'un atelier sans quitter sa page, puis essayez un titre de deux caractères.

Après la modification du titre, regardez le fil d'Ariane, en haut de la page : il affiche encore l'ancien. Un frame ne met à jour que lui-même. Pour mettre à jour plusieurs zones en une seule réponse, il faut les Turbo Streams du step 13.
