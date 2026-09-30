# Step 14 - Turbo Streams : s'inscrire sans recharger la page

> **Départ** : la fin du step 13 (ou `origin/step-13`) · **Fichiers fournis** : aucun · **Solution** : `origin/step-14`

## Objectifs

- Mettre à jour plusieurs zones d'une page en une seule réponse
- Répondre en `turbo_stream` depuis un contrôleur, en gardant une réponse HTML de repli
- Connaître les actions `append`, `update`, `replace` et `remove`
- Mettre à jour les autres navigateurs ouverts sur la même page

## 14.1 Plusieurs zones à mettre à jour

Une inscription redirige vers la session, et toute la page est redessinée. Pourtant, seules quatre zones changent : la liste des inscrits, les places restantes, le badge de statut (la session peut devenir complète) et le formulaire (vidé, ou remplacé par « Plus aucune place disponible. »).

Un frame remplace **une** zone. Un Turbo Stream est une réponse faite d'une liste d'instructions : « ajoute ce HTML à la fin de tel élément », « remplace le contenu de tel autre ». Chaque instruction vise un élément par son `id`.

> Doc : [Turbo Streams](https://turbo.hotwired.dev/handbook/streams)

## 14.2 Des cibles

**À vous.** Donnez un `id` aux quatre zones, dans `app/views/sessions/show.html.erb` :

- les places restantes : `<dd class="col-sm-9" id="remaining_seats">`
- le badge : `<span id="status_badge"><%= status_badge(@session) %></span>`
- la liste : `<tbody id="registrations">`. Retirez le `if` / `else` qui entoure le tableau : il est toujours affiché, même vide, pour que la cible existe.
- le formulaire : déplacez le `if` / `else` du step 07 dans le partial `registrations/_form.html.erb`, le tout dans un `<div id="registration_form">`. Dans `show.html.erb`, il ne reste que `<%= render "registrations/form", session: @session %>`. Dans le partial, la session s'appelle `session`, pas `@session`.

Rechargez la page d'une session : rien n'a changé à l'écran.

## 14.3 La réponse en stream

Pour un emprunt de livre, le contrôleur répond en stream quand la requête vient de Turbo, et garde la redirection pour les autres (les tests, un navigateur sans JavaScript) :

```ruby
# LoansController#create, en cas de succès
respond_to do |format|
  format.turbo_stream
  format.html { redirect_to @book, notice: "Emprunt enregistré." }
end
```

`format.turbo_stream` sans bloc rend le template `create.turbo_stream.erb`, qui contient les instructions :

```erb
<%# app/views/loans/create.turbo_stream.erb %>
<%= turbo_stream.append "loans", @loan %>
<%= turbo_stream.update "available_copies", @book.available_copies %>
<%= turbo_stream.replace "loan_form", partial: "loans/form", locals: { book: @book } %>
```

| Action | Effet |
| --- | --- |
| `append` / `prepend` | ajoute à la fin / au début de la cible |
| `update` | remplace le contenu de la cible, garde la balise |
| `replace` | remplace la cible elle-même, balise comprise |
| `remove` | supprime la cible |

`turbo_stream.append "loans", @loan` rend le partial `loans/_loan` : la convention du step 04.

**À vous.** Dans `RegistrationsController#create`, remplacez la redirection du succès par un `respond_to`, puis écrivez `app/views/registrations/create.turbo_stream.erb` avec quatre instructions :

1. ajouter l'inscription à la fin de `registrations`
2. mettre à jour `remaining_seats` avec `@session.remaining_seats`
3. mettre à jour `status_badge` avec `status_badge(@session)`
4. remplacer `registration_form` par le partial du formulaire, rendu à nouveau

Inscrivez quelqu'un : la ligne apparaît, le compteur baisse, le formulaire se vide, et la page n'est pas rechargée. Prenez la dernière place d'une session : le badge passe à « Complète » et le formulaire laisse la place au message. Dans l'onglet Réseau, lisez la réponse : du HTML, découpé en balises `<turbo-stream action="..." target="...">`.

Relancez `bin/rails test` : les tests ne passent pas par Turbo et reçoivent toujours la redirection.

> Doc : [Streaming From HTTP Responses](https://turbo.hotwired.dev/handbook/streams#streaming-from-http-responses)

## 14.4 À vous : la désinscription

**À vous.** Même traitement pour `destroy` :

- dans l'action, l'inscription et sa session passent dans des variables d'instance, `@registration` et `@session`, pour que le template les lise
- un `respond_to` avec `format.turbo_stream`, et la redirection actuelle dans `format.html`
- un template `destroy.turbo_stream.erb` : il retire la ligne (`turbo_stream.remove @registration`), puis met à jour le compteur, le badge et le formulaire, comme à l'inscription

Vérifiez sur une session complète : désinscrivez quelqu'un, la ligne disparaît, le badge repasse à « Publiée », le formulaire revient.

## 14.5 La seconde fenêtre

Ouvrez la même session dans **deux fenêtres** côte à côte. Inscrivez quelqu'un dans la première : la seconde ne bouge pas, elle n'a rien demandé. Pour la prévenir, le serveur doit lui **pousser** le changement, par une connexion qui reste ouverte (un WebSocket, géré par Action Cable).

1. En haut de `sessions/show.html.erb`, abonnez la page aux messages de cette session :

   ```erb
   <%= turbo_stream_from @session %>
   ```

2. Dans `Registration`, diffusez chaque changement aux pages abonnées à la session :

   ```ruby
   broadcasts_refreshes_to :session
   ```

Rechargez les deux fenêtres, puis inscrivez et désinscrivez quelqu'un dans la première : la seconde suit. Elle reçoit un seul message, `refresh`, et recharge son contenu. Dans le log du serveur, cherchez la ligne `[ActionCable] Broadcasting to`.

`broadcasts_refreshes_to` pose des callbacks `after_commit` sur le modèle : le mécanisme du step 08.

> Doc : [Broadcasting Page Refreshes](https://turbo.hotwired.dev/handbook/page_refreshes#broadcasting-page-refreshes)
