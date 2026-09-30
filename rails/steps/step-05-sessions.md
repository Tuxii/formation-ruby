# Step 05 - Les sessions d'un atelier

> **Départ** : la fin du step 04 (ou `origin/step-04`) · **Fichiers fournis** : au 5.5 · **Solution** : `origin/step-05`

## Objectifs

- Relier deux modèles avec `belongs_to` et `has_many`
- Donner des noms à un statut stocké en entier avec `enum`
- Imbriquer des routes : une session se crée depuis son atelier
- Écrire un contrôleur CRUD à la main, action par action

## 5.1 Un atelier a lieu plusieurs fois

L'atelier de céramique a lieu le 3 octobre, puis le 10, avec des jauges différentes. Chaque date est une **session** : un atelier, une date de début, une capacité, un statut.

Cette fois, pas de scaffold : le générateur ne crée que le modèle et sa migration. Le contrôleur, vous l'écrirez.

```bash
bin/rails generate model Session workshop:references starts_at:datetime capacity:integer status:integer --no-test-framework
```

`--no-test-framework` : pas de tests générés, nous écrirons les nôtres au step 10.

**Avant de migrer**, ouvrez la migration dans `db/migrate/` et modifiez-la :

- `starts_at` et `capacity` obligatoires : `null: false`
- `status` vaut `0` par défaut et n'est jamais nul : `null: false, default: 0`

```bash
bin/rails db:migrate
```

`workshop:references` a créé une colonne `workshop_id`, un index et une clé étrangère vers `workshops` : relisez la table `sessions` dans `db/schema.rb`.

> Doc : [Active Record Migrations - Column Modifiers](https://guides.rubyonrails.org/active_record_migrations.html#column-modifiers)

## 5.2 Les associations

Le générateur a écrit `belongs_to :workshop` dans `app/models/session.rb`. Écrivez l'autre côté dans `Workshop` :

```ruby
has_many :sessions, dependent: :destroy
```

Ajoutez à `Session` deux validations : `starts_at` présent, `capacity` entier strictement positif (comme `duration_minutes` au step 02, sans `allow_nil`).

En console (`bin/rails console`) :

```ruby
workshop = Workshop.find_by(title: "Initiation à la céramique")
workshop.sessions
workshop.sessions.create!(starts_at: 1.week.from_now, capacity: 8)
workshop.sessions.count
workshop.sessions.first.workshop.title
```

Ces méthodes (`sessions`, `sessions.create!`, `workshop`) sont générées par `has_many` et `belongs_to`. `workshop.sessions.create!` remplit `workshop_id` tout seul.

```ruby
session = Session.new
session.valid?
session.errors.full_messages
```

Vous n'avez écrit aucune validation sur l'atelier, et pourtant « Atelier doit exister » : `belongs_to` rend l'association obligatoire.

Enfin, `dependent: :destroy` supprime les sessions avec leur atelier. Créez un atelier en console, donnez-lui une session, supprimez-le avec `destroy`, et lisez le SQL : deux `DELETE`.

> Doc : [Active Record Associations](https://guides.rubyonrails.org/association_basics.html)

## 5.3 Le statut : `enum`

La colonne `status` stocke un entier. On veut manipuler des noms : brouillon, publiée, complète, annulée. Dans `Session` :

```ruby
enum :status, { draft: 0, published: 1, full: 2, cancelled: 3 }
```

En console, après `reload!` :

```ruby
session = Session.last
session.status
session.draft?
session.published!
session.status
Session.published.count
Session.statuses
```

La base stocke `1`, Ruby renvoie `"published"`. `enum` a généré les méthodes `draft?`, `published!`... et les scopes `Session.published`, `Session.draft`... avec `define_method`, comme à l'exercice 6.1.

On écrit le hash avec ses entiers : la correspondance nom / entier reste la même si on ajoute un statut plus tard.

> Doc : [ActiveRecord::Enum](https://api.rubyonrails.org/classes/ActiveRecord/Enum.html)

## 5.4 Des routes imbriquées

Une session se crée depuis la page de son atelier : l'URL de création doit contenir l'atelier (`/workshops/3/sessions/new`). Une fois créée, la session a sa propre URL (`/sessions/12`). Dans `config/routes.rb`, remplacez la ligne `resources :workshops` par :

```ruby
resources :workshops do
  resources :sessions, only: %i[ new create ]
end
resources :sessions, except: %i[ new create ]
```

```bash
bin/rails routes -g session
```

Sept actions, comme pour les ateliers au step 04. Seules `new` et `create` passent par l'atelier.

> Doc : [Nested Resources](https://guides.rubyonrails.org/routing.html#nested-resources)

## 5.5 Les vues et les données

Les vues sont fournies, avec le helper des statuts et les seeds. Copiez-les et chargez les données :

```bash
cp -r ../rails/fournis/step-05/. .
bin/rails db:seed
```

Dans la navbar, décommentez le lien « Sessions », puis cliquez dessus : `uninitialized constant SessionsController`. La route existe, les vues aussi, mais pas le contrôleur.

## 5.6 Le contrôleur, action par action

Gardez `app/controllers/workshops_controller.rb` ouvert à côté : c'est votre modèle. Après chaque action, rechargez la page concernée.

**`index`.** Créez `app/controllers/sessions_controller.rb` :

```ruby
class SessionsController < ApplicationController
  # GET /sessions
  def index
    @sessions = Session.order(:starts_at)
  end
end
```

La liste des sessions s'affiche.

**`show`.** Cliquez sur une session : `NoMethodError` dans la vue. L'action `show` n'existe pas, mais sa vue oui : Rails la rend quand même (la convention du step 03), avec un `@session` qui vaut `nil`. Ajoutez l'action :

```ruby
# GET /sessions/1
def show
  @session = Session.find(params.expect(:id))
end
```

**`new` et `create`.** Ces deux actions reçoivent l'atelier dans l'URL (`params[:workshop_id]`) : on le charge avant elles, et on construit la session depuis lui.

```ruby
before_action :set_workshop, only: %i[ new create ]

# GET /workshops/1/sessions/new
def new
  @session = @workshop.sessions.build
end

# POST /workshops/1/sessions
def create
  @session = @workshop.sessions.build(session_params)

  if @session.save
    redirect_to @session, notice: "Session programmée."
  else
    render :new, status: :unprocessable_content
  end
end

private
  def set_workshop
    @workshop = Workshop.find(params.expect(:workshop_id))
  end

  def session_params
    params.expect(session: [ :starts_at, :capacity, :status ])
  end
```

`workshop_id` n'est pas dans `session_params` : l'atelier vient de l'URL, pas du formulaire. Depuis la page d'un atelier, programmez une session, puis essayez en laissant la date vide : le formulaire revient avec l'erreur.

**À vous : `edit`, `update` et `destroy`**, sur le modèle de `WorkshopsController` :

- `edit` et `update` chargent la session comme `show`. Pour ne pas répéter la ligne, écrivez une méthode privée `set_session` et un `before_action :set_session, only: %i[ show edit update destroy ]`
- `update` : `@session.update(session_params)`, puis `redirect_to` avec « Session mise à jour. » et `status: :see_other`, ou `render :edit` avec le statut `:unprocessable_content`
- `destroy` : `@session.destroy!`, puis redirigez vers l'atelier de la session (`@session.workshop`) avec « Session supprimée. » et `status: :see_other`

Modifiez une session, puis supprimez-la.

Comparez votre contrôleur avec `WorkshopsController` : les mêmes sept actions, sans les blocs `format.json` du scaffold.

Le formulaire fourni `sessions/_form.html.erb` reçoit `[session.workshop, session]` pour une nouvelle session et `session` seule pour une session existante : `form_with` en déduit l'URL, `/workshops/3/sessions` dans un cas, `/sessions/12` dans l'autre.

Attention au nom : dans un contrôleur ou une vue, `session` désigne aussi la session HTTP de Rails (les données gardées entre deux requêtes). Dans nos vues, c'est la variable locale qui passe en premier.

> Doc : [Action Controller Overview](https://guides.rubyonrails.org/action_controller_overview.html)
