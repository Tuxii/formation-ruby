# Step 13 - Turbo Frames : modifier sur place

> **Départ** : la fin du step 12 (ou `origin/step-12`) · **Fichiers fournis** : aucun · **Solution** : `origin/step-13`

## Objectifs

- Voir ce que Turbo Drive fait depuis le début, sans que vous ayez écrit de JavaScript
- Découper une page en zones qui se mettent à jour seules, avec `turbo_frame_tag`
- Modifier un enregistrement sans quitter sa page
- Savoir sortir d'un frame

## 13.1 Turbo Drive est déjà là

Ouvrez les outils de développement du navigateur, onglet Réseau, filtre « Fetch/XHR ». Naviguez entre le catalogue, un atelier et une session : chaque clic est une requête `fetch`, la page n'est jamais rechargée en entier.

C'est Turbo Drive, installé par défaut (`app/javascript/application.js` importe `@hotwired/turbo-rails`) : il intercepte les clics sur les liens et les envois de formulaires, fait la requête lui-même, et remplace le `<body>` par celui de la réponse.

Conséquence pour les formulaires : dans `SessionsController#create`, retirez `status: :unprocessable_content` du `render :new`, puis programmez une session en laissant la date vide. Il ne se passe rien à l'écran, et la console du navigateur affiche `Form responses must redirect to another location`. Remettez le statut.

Après l'envoi d'un formulaire, Turbo attend une redirection (le succès) ou un statut d'erreur comme `422` (l'échec) pour afficher la réponse. C'est la raison des statuts que vous avez écrits au step 05.

> Doc : [Turbo Drive - Form Submissions](https://turbo.hotwired.dev/handbook/drive#form-submissions)

## 13.2 Modifier une session sur place

Pour changer la capacité d'une session, on quitte sa page, on modifie, on revient. On veut que le formulaire apparaisse **à la place** des informations, sans quitter la page.

Un Turbo Frame est une zone délimitée par `turbo_frame_tag`. Pour un livre :

```erb
<%# app/views/books/show.html.erb %>
<%= turbo_frame_tag "book_details" do %>
  <h1><%= @book.title %></h1>
  <p><%= pluralize(@book.copies, "exemplaire", plural: "exemplaires") %></p>

  <%= link_to "Modifier", edit_book_path(@book) %>
<% end %>

<%# app/views/books/edit.html.erb : un frame du même nom %>
<%= turbo_frame_tag "book_details" do %>
  <%= render "form", book: @book %>

  <%= link_to "Annuler", @book %>
<% end %>
```

Un lien ou un formulaire placé **dans** un frame ne change pas de page : Turbo fait la requête, cherche dans la réponse le frame qui porte le même `id`, et remplace le contenu du frame affiché par le sien. Le reste de la réponse est ignoré, et le contrôleur ne change pas.

**À vous.** Faites-le pour la page d'une session, avec un frame `session_details` :

- dans `sessions/show.html.erb`, le frame entoure le titre, le badge et la liste `<dl>`, et le lien « Modifier » passe dans le frame, sous la liste
- dans `sessions/edit.html.erb`, le même frame entoure le formulaire, avec un lien « Annuler » vers la session à la place du lien de retour

Cliquez sur « Modifier » : le formulaire prend la place des informations, le reste de la page ne bouge pas. Changez la capacité et enregistrez. Recommencez en vidant la date : l'erreur s'affiche sur place. Dans l'onglet Réseau, la requête porte un en-tête `Turbo-Frame: session_details`.

Le message « Session mise à jour. » ne s'affiche plus : il est rendu par le layout, hors du frame.

> Doc : [Turbo Frames](https://turbo.hotwired.dev/handbook/frames)

## 13.3 Sortir du frame

Dans le frame de `sessions/show.html.erb`, à côté de « Modifier », ajoutez un lien vers l'atelier :

```erb
<%= link_to "Voir l'atelier", @session.workshop, class: "btn btn-link btn-sm" %>
```

Cliquez : « Content missing ». La page de l'atelier ne contient pas de frame `session_details`, Turbo n'a rien à mettre à la place. Pour qu'un lien placé dans un frame change toute la page, ajoutez-lui :

```erb
data: { turbo_frame: "_top" }
```

Tout ce qui est dans un frame reste dans le frame, sauf indication contraire. C'est pour cela que le bouton « Supprimer » reste en dehors.

> Doc : [Targeting Navigation Into or Out of a Frame](https://turbo.hotwired.dev/handbook/frames#targeting-navigation-into-or-out-of-a-frame)

## 13.4 À vous : un atelier sur place

**À vous.** Faites la même chose pour les ateliers, avec un frame `workshop_details` :

- dans `workshops/show.html.erb`, le frame entoure le titre, le badge, la durée, le nombre de participants, la description et le lien de téléchargement du support, avec le lien « Modifier » à l'intérieur
- dans `workshops/edit.html.erb`, le même frame entoure le formulaire, avec un lien « Annuler »

Vérifiez : modifiez le titre d'un atelier sans quitter sa page, puis essayez un titre de deux caractères. Joignez un support PDF depuis le frame : le lien de téléchargement apparaît sans recharger la page.

Après la modification du titre, regardez le fil d'Ariane, en haut de la page : il affiche encore l'ancien. Un frame ne met à jour que lui-même. Pour mettre à jour plusieurs zones en une seule réponse, il faut les Turbo Streams du step 14.
