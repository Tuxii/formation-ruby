# Step 11 - Des notes sur les ateliers et les sessions

> **Départ** : la fin du step 10 (ou `origin/step-10`) · **Fichiers fournis** : au 11.3 · **Solution** : `origin/step-11`

## Objectifs

- Relier un modèle à plusieurs autres avec une association polymorphe
- Écrire un contrôleur et un partial qui servent à deux modèles

## 11.1 Une table pour deux modèles

Les organisateurs veulent prendre des notes internes : sur un atelier (« Commander de l'argile »), et sur une session (« Salle 2, prévoir des tabliers »). Plutôt qu'une table de notes par modèle, une seule table `notes`, dont chaque ligne dit **à quel type d'objet** elle appartient.

```bash
bin/rails generate model Note body:text "notable:references{polymorphic}" --no-test-framework
```

Les guillemets empêchent le terminal d'interpréter les accolades. **Avant de migrer**, rendez `body` obligatoire (`null: false`), puis :

```bash
bin/rails db:migrate
```

Lisez la table `notes` dans `db/schema.rb` : deux colonnes, `notable_type` (le nom de la classe, `"Workshop"` ou `"Session"`) et `notable_id` (l'id dans la table correspondante).

> Doc : [Polymorphic Associations](https://guides.rubyonrails.org/association_basics.html#polymorphic-associations)

## 11.2 Les associations

Le générateur a écrit `belongs_to :notable, polymorphic: true` dans `Note`. Ajoutez une validation de présence sur `body`.

Dans `Workshop` **et** dans `Session` :

```ruby
has_many :notes, as: :notable, dependent: :destroy
```

`as: :notable` dit à Rails de chercher les notes par les deux colonnes. En console :

```ruby
workshop = Workshop.first
workshop.notes.create!(body: "Commander de l'argile")
session = Session.first
session.notes.create!(body: "Salle 2, prévoir des tabliers")

Note.pluck(:notable_type, :notable_id, :body)
Note.last.notable
puts workshop.notes.to_sql
```

`note.notable` renvoie un `Workshop` ou une `Session` selon la ligne : Rails lit `notable_type` pour savoir quelle classe instancier.

## 11.3 Un formulaire sur les deux pages

Les notes se créent depuis la page d'un atelier ou d'une session. Ajoutez une route imbriquée dans les deux blocs de `config/routes.rb` :

```ruby
resources :workshops do
  resources :sessions, only: %i[ new create ]
  resources :notes, only: :create
end
resources :sessions, except: %i[ new create ] do
  resources :registrations, only: :create
  resources :notes, only: :create
end
```

```bash
bin/rails routes -g note
```

Deux URL, `/workshops/1/notes` et `/sessions/1/notes`, pour un seul contrôleur. Créez `app/controllers/notes_controller.rb`. Avant `create`, on charge l'objet annoté, atelier ou session selon le paramètre présent dans l'URL :

```ruby
class NotesController < ApplicationController
  before_action :set_notable

  private
    def set_notable
      if params[:workshop_id]
        @notable = Workshop.find(params[:workshop_id])
      else
        @notable = Session.find(params[:session_id])
      end
    end
end
```

**À vous.** Écrivez l'action `create` et `note_params`, sur le modèle de `RegistrationsController` :

- `create` construit la note depuis `@notable.notes`, avec `note_params`
- si elle s'enregistre : redirection vers `@notable`, avec le message « Note ajoutée. »
- sinon : redirection vers `@notable`, avec l'alerte « Une note ne peut pas être vide. »
- `note_params` autorise `body`, envoyé sous la clé `note`

`create` ne sait pas si `@notable` est un atelier ou une session, et n'a pas besoin de le savoir : les deux ont `notes`, et `redirect_to` trouve l'URL de chacun.

Copiez le partial fourni et les seeds :

```bash
cp -r ../rails/fournis/step-11/. .
bin/rails db:seed
```

Le partial `notes/_notes.html.erb` affiche les notes et le formulaire d'un objet `notable`. Rendez-le sur la page d'un atelier et sur celle d'une session, avant les boutons « Modifier » et « Supprimer » :

```erb
<%= render "notes/notes", notable: @workshop %>
```

```erb
<%= render "notes/notes", notable: @session %>
```

Ajoutez une note sur un atelier, puis sur une session. Le formulaire du partial reçoit `[notable, Note.new]` : `form_with` en déduit `/workshops/1/notes` ou `/sessions/1/notes`.

## 11.4 Ce que la base ne garantit plus

Dans `registrations`, `session_id` a une clé étrangère : la base refuse une inscription vers une session qui n'existe pas. Pour `notes.notable_id`, impossible : la colonne pointe tantôt vers `workshops`, tantôt vers `sessions`. C'est `dependent: :destroy` qui supprime les notes avec leur atelier : l'intégrité repose sur le code.
