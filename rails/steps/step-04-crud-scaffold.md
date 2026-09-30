# Step 04 - CRUD des ateliers avec le scaffold

> **Départ** : la fin du step 03 (ou `origin/step-03`) · **Fichiers fournis** : au 4.3 · **Solution** : `origin/step-04`

## Objectifs

- Générer un CRUD complet avec le scaffold
- Savoir lire un contrôleur Rails : actions, `before_action`, paramètres autorisés, redirections
- Brancher des vues, des partials et un helper
- Afficher les erreurs de validation et les messages flash

## 4.1 Gérer le catalogue depuis le navigateur

Pour l'instant, les ateliers ne se créent qu'en console. Le scaffold génère tout ce qu'il faut pour les lister, les afficher, les créer, les modifier et les supprimer. Le modèle existe déjà : on demande au générateur de ne pas y toucher.

```bash
bin/rails generate scaffold Workshop title description:text duration_minutes:integer published:boolean --skip --skip-collision-check
```

`--skip` garde les fichiers qui existent déjà, `--skip-collision-check` laisse le générateur continuer alors que la classe `Workshop` existe. Ouvrez http://localhost:3000/workshops : créez, modifiez et supprimez un atelier.

Le message de confirmation s'affiche deux fois : une par la vue du scaffold, une par le partial `_flash` du layout. Les vues du 4.3 règlent ça.

> Doc : [Generating Code](https://guides.rubyonrails.org/command_line.html#generating-code)

## 4.2 Lire le contrôleur généré

Le générateur a ajouté `resources :workshops` dans `config/routes.rb`. Cette ligne déclare les routes des 7 actions d'une ressource (`PUT` double `PATCH`, d'où 8 lignes) :

```bash
bin/rails routes -g workshop
```

| Verbe et URL | Action | Ce qu'elle fait |
| --- | --- | --- |
| `GET /workshops` | `index` | la liste |
| `GET /workshops/1` | `show` | un atelier |
| `GET /workshops/new` | `new` | le formulaire de création |
| `POST /workshops` | `create` | enregistre, puis redirige vers l'atelier |
| `GET /workshops/1/edit` | `edit` | le formulaire de modification |
| `PATCH /workshops/1` | `update` | enregistre, puis redirige vers l'atelier |
| `DELETE /workshops/1` | `destroy` | supprime, puis redirige vers la liste |

Ouvrez `app/controllers/workshops_controller.rb` et repérez :

- `before_action :set_workshop` : avant `show`, `edit`, `update` et `destroy`, charge l'atelier de l'URL dans `@workshop`
- `workshop_params` : la liste des champs que le formulaire a le droit de modifier. Un champ absent de la liste est ignoré.
- dans `create`, si `save` échoue : `render :new` réaffiche le formulaire avec les erreurs et les valeurs saisies, avec le statut `422`. Si `save` réussit : `redirect_to`, qui envoie le navigateur vers la page de l'atelier.

Les blocs `format.json` servent une API JSON générée en même temps. Nous ne nous en servirons pas.

> Doc : [Resource Routing](https://guides.rubyonrails.org/routing.html#resource-routing-the-rails-default)
> Doc : [Strong Parameters](https://guides.rubyonrails.org/action_controller_overview.html#strong-parameters)

## 4.3 Les vues Bootstrap

Les vues du scaffold sont nues. Copiez par-dessus les vues fournies :

```bash
cp -r ../rails/fournis/step-04/. .
```

Rechargez la liste des ateliers : elle plante, car les vues appellent une méthode `publication_badge` qui n'existe pas encore.

**À vous.** Écrivez `publication_badge(workshop)` dans `app/helpers/workshops_helper.rb` : elle renvoie un badge vert « Publié » si l'atelier est publié, un badge gris « Brouillon » sinon. Un badge se construit avec `tag.span` :

```ruby
tag.span("Publié", class: "badge text-bg-success")
```

Pour le gris, la classe est `text-bg-secondary`.

Toute méthode d'un module de `app/helpers/` est appelable depuis n'importe quelle vue. `tag.span` construit la balise et échappe son contenu.

> Doc : [Action View Helpers](https://guides.rubyonrails.org/action_view_helpers.html)

## 4.4 Les partials

Ouvrez `app/views/workshops/index.html.erb` : `<%= render @workshops %>` affiche toute la liste. Rails rend le partial `workshops/_workshop.html.erb` une fois par atelier, avec une variable locale `workshop`.

Même mécanisme dans le formulaire : `<%= render "shared/errors", record: workshop %>` rend `shared/_errors.html.erb` avec une variable locale `record`.

> Doc : [Using Partials](https://guides.rubyonrails.org/layouts_and_rendering.html#using-partials)

## 4.5 Erreurs et messages flash

Créez un atelier avec un titre de deux caractères et une durée de 0 : le formulaire revient avec les erreurs, et vos valeurs sont toujours là.

Créez ensuite un atelier valide : le message de confirmation vient de l'option `notice:` du `redirect_to`. Le partial `_flash` du layout l'affiche sur la page suivante. Traduisez en français les trois messages du contrôleur (« Atelier créé. », « Atelier mis à jour. », « Atelier supprimé. »).

> Doc : [The Flash](https://guides.rubyonrails.org/action_controller_overview.html#the-flash)
> Doc : [Displaying Validation Errors in Views](https://guides.rubyonrails.org/active_record_validations.html#displaying-validation-errors-in-views)

## 4.6 Finitions

- Dans l'action `index`, triez les ateliers par titre : `Workshop.order(:title)`
- Dans la navbar, décommentez le lien « Catalogue »
- Sur la page d'accueil, ajoutez un lien vers le catalogue : `<%= link_to "Voir le catalogue", workshops_path, class: "btn btn-primary" %>`
- Relancez `bin/rails test` : le scaffold a aussi écrit `test/controllers/workshops_controller_test.rb`, et tout passe
