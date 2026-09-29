# Step 04 - CRUD des ateliers, et lire du code généré

> **Départ** : la fin du step 03 (ou `origin/step-03`) · **Fichiers fournis** : au 4.3 · **Solution** : `origin/step-04`

## Objectifs

- Générer un CRUD complet avec le scaffold
- **Lire** le code généré : actions, routes, `before_action`, strong parameters, redirections, rendu en cas d'erreur
- Brancher des vues fournies, des partials et un helper
- Afficher les erreurs de validation et les messages flash

## 4.1 Gérer le catalogue sans la console

Pour l'instant, les ateliers ne se créent qu'en console. Il faut pouvoir les lister, les afficher, les créer, les modifier et les supprimer depuis le navigateur : les 7 actions classiques d'une ressource.

Le modèle existe déjà. Faites générer tout le reste par le scaffold, sans toucher à ce qui existe :

```bash
bin/rails generate scaffold Workshop title description:text duration_minutes:integer published:boolean --skip --skip-collision-check
```

`--skip` garde les fichiers qui existent déjà ; `--skip-collision-check` laisse le générateur continuer alors que la classe `Workshop` existe. Lisez la sortie : ce qui est créé, ce qui est sauté (`skip`), ce qui est identique. Testez le CRUD sur http://localhost:3000/workshops.

> Doc : [Generating Code](https://guides.rubyonrails.org/command_line.html#generating-code)

## 4.2 Lire le code généré

Sans rien modifier, ouvrez `app/controllers/workshops_controller.rb` et lancez `bin/rails routes -g workshop`. Pour chacune des 7 actions, notez le verbe HTTP et l'URL, puis la vue rendue ou la redirection.

Puis répondez :

- `before_action :set_workshop` : quand est-il exécuté, et pour quelles actions ?
- `workshop_params` : que fait `params.expect`, et pourquoi cette liste existe-t-elle ?
- `render :new, status: :unprocessable_content` : pourquoi un `render` et pas un `redirect_to` quand la validation échoue ?

> Doc : [Action Controller Overview](https://guides.rubyonrails.org/action_controller_overview.html)
> Doc : [Strong Parameters](https://guides.rubyonrails.org/action_controller_overview.html#strong-parameters)
> Doc : [Resource Routing](https://guides.rubyonrails.org/routing.html#resource-routing-the-rails-default)

## 4.3 Brancher les vues fournies

Les vues du scaffold sont nues. Copiez par-dessus les vues Bootstrap fournies :

```bash
cp -r ../rails/fournis/step-04/. .
```

Rechargez la liste des ateliers : elle plante. Quelle méthode manque ?

Écrivez `publication_badge(workshop)` dans `app/helpers/workshops_helper.rb` : il renvoie un badge Bootstrap vert « Publié » ou gris « Brouillon ». Utilisez `tag.span` plutôt qu'une chaîne HTML construite à la main : pourquoi ?

Contrairement à une extension Twig, rien à déclarer : toute méthode d'un module de `app/helpers/` est appelable depuis n'importe quelle vue.

> Doc : [Action View Helpers](https://guides.rubyonrails.org/action_view_helpers.html)
> Doc : [Bootstrap Badges](https://getbootstrap.com/docs/5.3/components/badge/)

## 4.4 Partials

Ouvrez `app/views/workshops/index.html.erb` : il contient `<%= render @workshops %>`, et rien d'autre pour afficher la liste.

- Quel fichier est rendu, et combien de fois ?
- D'où vient la variable `workshop` dans `_workshop.html.erb` ? Et `record` dans `shared/_errors`, rendu par `<%= render "shared/errors", record: workshop %>` ?

> Doc : [Using Partials](https://guides.rubyonrails.org/layouts_and_rendering.html#using-partials)

## 4.5 Erreurs de validation et flash

Soumettez un atelier avec un titre de deux caractères et une durée de 0. Observez le code HTTP dans la ligne `Completed` du log, les messages d'erreur, et les valeurs que vous aviez saisies.

Puis créez un atelier valide. Le message de confirmation vient du `notice:` du contrôleur, affiché par le partial `_flash` du layout. Traduisez les trois messages du contrôleur en français.

> Doc : [The Flash](https://guides.rubyonrails.org/action_controller_overview.html#the-flash)
> Doc : [Displaying Validation Errors in Views](https://guides.rubyonrails.org/active_record_validations.html#displaying-validation-errors-in-views)

## 4.6 Finitions

- Triez les ateliers par titre dans l'action `index`
- Dans la navbar, décommentez le lien « Catalogue »
- Sur la page d'accueil, ajoutez un bouton vers le catalogue
- Relancez `bin/rails test` : tout passe. Le scaffold a aussi généré `test/controllers/workshops_controller_test.rb`, qui resservira au step 18.

> Doc : [Ordering Records](https://guides.rubyonrails.org/active_record_querying.html#ordering-records)
