# Step 06 - Participants et inscriptions

> **Départ** : la fin du step 05 (ou `origin/step-05`) · **Fichiers fournis** : aux 6.4 et 6.5 · **Solution** : `origin/step-06`

## Objectifs

- Relier deux modèles par un modèle de jointure, avec `has_many :through`
- Garantir une règle d'unicité deux fois : par une validation et par un index unique
- Écrire le contrôleur d'un formulaire d'inscription

## 6.1 Qui vient à quelle session ?

Une personne peut s'inscrire à plusieurs sessions, et une session a plusieurs inscrits. Entre les deux, une table d'inscriptions : chaque ligne relie une session et un participant.

```bash
bin/rails generate model Participant name:string email:string:uniq --no-test-framework
bin/rails generate model Registration session:references participant:references --no-test-framework
```

**Avant de migrer** :

- dans la migration des participants, `name` et `email` sont obligatoires (`null: false`). `email:string:uniq` a déjà ajouté un index unique sur `email`.
- dans la migration des inscriptions, une personne ne s'inscrit qu'une fois à une session. Ajoutez après le `create_table` un index unique sur le couple :

  ```ruby
  add_index :registrations, [ :session_id, :participant_id ], unique: true
  ```

```bash
bin/rails db:migrate
```

## 6.2 `has_many :through`

`Registration` a déjà ses deux `belongs_to`. Déclarez l'autre côté dans `Participant` :

```ruby
has_many :registrations, dependent: :destroy
has_many :sessions, through: :registrations
```

`through` traverse la table de jointure : `participant.sessions` fait la jointure avec `registrations` pour vous.

**À vous.** Écrivez les deux lignes symétriques dans `Session` : ses inscriptions, supprimées avec elle, et ses participants à travers elles. Puis en console :

```ruby
session = Session.first
alice = Participant.create!(name: "Alice Martin", email: "alice@example.test")
session.registrations.create!(participant: alice)
session.participants
alice.sessions
```

Lisez le SQL de `session.participants` : un `INNER JOIN` sur `registrations`.

La console affiche `email: [FILTERED]` : Rails masque dans les logs et la console les attributs listés dans `config/initializers/filter_parameter_logging.rb`. `alice.email` renvoie la vraie valeur.

`through` peut enchaîner deux associations. Les participants d'un atelier passent par ses sessions, puis par leurs inscriptions. Dans `Workshop` :

```ruby
has_many :registrations, through: :sessions
has_many :participants, -> { distinct }, through: :registrations
```

`distinct` compte une seule fois une personne venue à deux sessions du même atelier. Sur la page d'un atelier, sous la durée, affichez le nombre de participants :

```erb
<p><%= pluralize(@workshop.participants.count, "participant", plural: "participants") %> depuis le début.</p>
```

> Doc : [The has_many :through Association](https://guides.rubyonrails.org/association_basics.html#has-many-through)

## 6.3 La même règle, à deux endroits

**À vous.** Dans `Participant`, écrivez les validations, comme au step 02 :

- le nom est présent
- l'email est présent, unique (`uniqueness: true`) et bien formé (`format: { with: URI::MailTo::EMAIL_REGEXP }`)

Vérifiez en console : `Participant.new(name: "Test", email: "pas-un-email").valid?`, puis `errors.full_messages`.

Dans `Registration` : un participant n'est inscrit qu'une fois par session. L'option `scope` limite l'unicité à une session :

```ruby
validates :participant_id, uniqueness: { scope: :session_id, message: "est déjà inscrit à cette session" }
```

La règle d'unicité est maintenant écrite deux fois :

- la **validation** donne un message lisible, affiché à l'utilisateur
- l'**index unique** est la garantie : la base refuse le doublon même quand une écriture contourne les validations (`save(validate: false)`, `insert_all`, du SQL écrit à la main)

En console, inscrivez Alice une seconde fois à la même session avec `create`, puis lisez `errors.full_messages`.

> Doc : [Uniqueness](https://guides.rubyonrails.org/active_record_validations.html#uniqueness)

## 6.4 Le formulaire d'inscription

Sur la page d'une session : un formulaire nom + email, et la liste des inscrits. La route de création est imbriquée sous les sessions. Remplacez la ligne `resources :sessions, except: %i[ new create ]` par :

```ruby
resources :sessions, except: %i[ new create ] do
  resources :registrations, only: :create
end
```

Copiez les vues fournies (le formulaire, une ligne d'inscrit, la page d'une session) :

```bash
cp -r ../rails/fournis/step-06/app .
```

Créez `app/controllers/registrations_controller.rb` avec l'action `create` :

```ruby
class RegistrationsController < ApplicationController
  # POST /sessions/1/registrations
  def create
    @participant = Participant.find_or_initialize_by(email: participant_params[:email])
    @participant.name = participant_params[:name] if @participant.new_record?
    @registration = @session.registrations.build(participant: @participant)

    if @participant.save && @registration.save
      redirect_to @session, notice: "Inscription de #{@participant.name} enregistrée."
    else
      errors = @participant.errors.full_messages + @registration.errors.full_messages
      redirect_to @session, alert: "Inscription impossible : #{errors.to_sentence}."
    end
  end
end
```

`find_or_initialize_by` cherche le participant par son email, et en prépare un nouveau, sans l'enregistrer, s'il n'existe pas : une personne qui revient garde son compte.

**À vous.** Il manque ce que `create` utilise, à écrire comme dans `SessionsController` au step 05 :

- `@session` : un `before_action :set_session` et sa méthode privée, qui charge la session de l'URL (`bin/rails routes -g registration` donne le nom du paramètre)
- `participant_params` : une méthode privée qui autorise `name` et `email`, envoyés par le formulaire sous la clé `participant`

Inscrivez quelqu'un depuis la page d'une session, puis réinscrivez la même personne : le message d'erreur vient de la validation du 6.3.

> Doc : [find_or_initialize_by (API)](https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-find_or_initialize_by)

## 6.5 Des inscrits dans les seeds

Copiez les seeds fournis, qui ajoutent 60 participants et leurs inscriptions, et chargez-les :

```bash
cp ../rails/fournis/step-06/db/seeds.rb db/seeds.rb
bin/rails db:seed
```

La session de cuisine du 8 octobre compte 40 inscrits. Sur celle de céramique du 10 octobre, il reste une place.
