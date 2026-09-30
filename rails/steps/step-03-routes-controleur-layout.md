# Step 03 - Routes, contrôleur, layout

> **Départ** : la fin du step 02 (ou `origin/step-02`) · **Fichiers fournis** : au 3.3 · **Solution** : `origin/step-03`

## Objectifs

- Générer un contrôleur et déclarer la route racine
- Passer une valeur du contrôleur à la vue
- Mettre en place le layout avec Bootstrap

## 3.1 Une page d'accueil

La page d'accueil de Rails n'est pas la nôtre : on veut une page qui affiche le nombre d'ateliers publiés.

```bash
bin/rails generate controller Pages home
```

Le générateur a créé `PagesController` avec une action `home`, la vue `app/views/pages/home.html.erb`, et une ligne dans `config/routes.rb`. Remplacez cette ligne par une route racine :

```ruby
root "pages#home"
```

Listez les routes de l'application, puis ouvrez http://localhost:3000 :

```bash
bin/rails routes -g root
```

> Doc : [Rails Routing from the Outside In](https://guides.rubyonrails.org/routing.html)

## 3.2 Du contrôleur à la vue

Dans l'action `home`, comptez les ateliers publiés :

```ruby
def home
  @published_workshops_count = Workshop.where(published: true).count
end
```

Remplacez le contenu de `app/views/pages/home.html.erb` par un titre et ce nombre, avec `pluralize` pour obtenir « 4 ateliers publiés » :

```erb
<h1>Ateliers à places limitées</h1>
<p><%= pluralize(@published_workshops_count, "atelier publié", plural: "ateliers publiés") %></p>
```

Rechargez la page. Deux conventions ont joué sans que vous les écriviez :

- l'action ne contient aucun `render` : Rails rend la vue qui porte le nom du contrôleur et de l'action, `pages/home`
- la vue lit `@published_workshops_count` : Rails copie les variables d'instance du contrôleur dans la vue

Une variable d'instance mal orthographiée dans la vue vaut `nil`, sans erreur. Essayez avec `@published_workshop_count` : la page annonce « 0 ateliers publiés », faux et plausible. Corrigez.

Dans le terminal de `bin/dev`, chaque requête est journalisée : l'URL, le contrôleur et l'action, le SQL, la vue rendue.

> Doc : [Layouts and Rendering](https://guides.rubyonrails.org/layouts_and_rendering.html#rendering-by-default-convention-over-configuration-in-action)

## 3.3 Le layout

`app/views/layouts/application.html.erb` enveloppe toutes les pages : chaque vue est insérée à l'endroit du `<%= yield %>`.

Copiez les partials fournis (`_navbar`, `_flash`, `_footer`) :

```bash
cp -r ../rails/fournis/step-03/. .
```

Dans le layout :

- déclarez la langue du document : `<html lang="fr">`
- ajoutez `<%= render "layouts/navbar" %>` en haut du `<body>` et `<%= render "layouts/footer" %>` en bas
- entourez `<%= yield %>` d'une balise `<main class="container">`, et ajoutez dans le `<main>`, juste avant `yield`, `<%= render "layouts/flash" %>`

Un partial est un morceau de vue réutilisable. Son nom de fichier commence par `_` (`_navbar.html.erb`), mais on l'appelle sans (`render "layouts/navbar"`).

> Doc : [Using Partials](https://guides.rubyonrails.org/layouts_and_rendering.html#using-partials)
> Doc : [Bootstrap Navbar](https://getbootstrap.com/docs/5.3/components/navbar/)

## 3.4 Le test généré

Le générateur a aussi écrit un test. Lancez-le :

```bash
bin/rails test
```

Il est en erreur (`E`) : `test/controllers/pages_controller_test.rb` appelle `pages_home_url`, la route que vous avez remplacée au 3.1. Remplacez `pages_home_url` par `root_url`, relancez : le test passe. Les tests sont le sujet du step 10.
