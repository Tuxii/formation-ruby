# Step 03 - Routes, contrôleur, layout

> **Départ** : la fin du step 02 (ou `origin/step-02`) · **Fichiers fournis** : au 3.3 · **Solution** : `origin/step-03`

## Objectifs

- Suivre une requête HTTP du navigateur jusqu'à la vue
- Générer un contrôleur et déclarer la route racine
- Comprendre ce que Rails fait sans qu'on lui demande : rendu implicite, variables d'instance partagées avec la vue
- Mettre en place le layout avec Bootstrap

## 3.1 Une page d'accueil

La page d'accueil de Rails n'est pas la nôtre : on veut une page qui affiche le nombre d'ateliers publiés.

```bash
bin/rails generate controller Pages home
```

Le générateur a ajouté une ligne dans `config/routes.rb`. Remplacez-la par une route racine qui pointe vers `pages#home`.

```bash
bin/rails routes
```

La commande liste toutes les routes, y compris celles que Rails ajoute lui-même. Filtrez avec `bin/rails routes -g root`, puis ouvrez http://localhost:3000.

> Doc : [Rails Routing from the Outside In](https://guides.rubyonrails.org/routing.html)

## 3.2 Du navigateur à la vue

Dans l'action `home`, calculez le nombre d'ateliers publiés dans une variable d'instance `@published_workshops_count`. Affichez-la dans `app/views/pages/home.html.erb` avec `pluralize` : pour obtenir « 4 ateliers publiés », regardez son option `plural:`.

Rechargez la page et lisez le log du serveur, dans le terminal de `bin/dev` (extrait) :

```
Started GET "/" for ::1 at ...
Processing by PagesController#home as HTML
  Workshop Count (0.1ms)  SELECT COUNT(*) FROM "workshops" WHERE "workshops"."published" = TRUE
  ↳ app/controllers/pages_controller.rb:3:in 'PagesController#home'
  Rendered pages/home.html.erb within layouts/application (Duration: 0.4ms | GC: 0.0ms)
  Rendered layout layouts/application.html.erb (Duration: 30.6ms | GC: 19.7ms)
Completed 200 OK in 50ms (Views: 33.4ms | ActiveRecord: 0.9ms (1 query, 0 cached) | GC: 19.7ms)
```

Que vous apprend la ligne `↳` ?

Deux choses se sont passées sans que vous les écriviez :

- l'action ne contient aucun `render`, et pourtant la vue `pages/home` a été rendue. Quelle convention Rails a-t-il appliquée ?
- la vue lit `@published_workshops_count`, une variable d'instance **du contrôleur**, sans que personne ne la lui passe comme avec `$this->render('...', ['count' => $count])`.

Rails copie les variables d'instance du contrôleur vers la vue avant le rendu. Une variable d'instance mal nommée donne donc un `nil` silencieux dans la vue, pas une erreur.

> Doc : [Layouts and Rendering](https://guides.rubyonrails.org/layouts_and_rendering.html#rendering-by-default-convention-over-configuration-in-action)
> Doc : [Action Controller Overview](https://guides.rubyonrails.org/action_controller_overview.html)

## 3.3 Le layout

`app/views/layouts/application.html.erb` enveloppe toutes les pages : chaque vue est rendue à l'endroit du `<%= yield %>`.

Copiez les partials fournis (`_navbar`, `_flash`, `_footer`) :

```bash
cp -r ../rails/fournis/step-03/. .
```

Modifiez le layout pour :

- rendre la navbar en haut du `<body>` et le footer en bas, avec `<%= render "layouts/navbar" %>`
- entourer `<%= render "layouts/flash" %>` et `<%= yield %>` d'une balise `<main class="container">`
- déclarer la langue du document (`<html lang="fr">`)

Rechargez la page : quelles lignes `Rendered` apparaissent maintenant dans le log ? Le nom de fichier d'un partial commence par `_`, mais on l'appelle sans.

> Doc : [Structuring Layouts](https://guides.rubyonrails.org/layouts_and_rendering.html#structuring-layouts)
> Doc : [Bootstrap Navbar](https://getbootstrap.com/docs/5.3/components/navbar/)

## 3.4 Pour finir

Lancez les tests :

```bash
bin/rails test
```

`test/controllers/pages_controller_test.rb`, généré avec le contrôleur, appelle la route que vous avez remplacée. Corrigez-le pour qu'il visite la page racine (`root_url`), puis relancez : le test passe.

Chaque générateur écrit aussi un test, qui peut être faux dès sa génération. Les tests reviennent au step 18.

> Doc : [Functional Testing for Controllers](https://guides.rubyonrails.org/testing.html#functional-testing-for-controllers)
