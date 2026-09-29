# Step 02 - Enrichir Workshop, comprendre où sont branchées les choses

> **Départ** : la fin du step 01 (ou `origin/step-01`) · **Fichiers fournis** : au 2.5 · **Solution** : `origin/step-02`

## Objectifs

- Faire évoluer une table avec une migration
- Ajouter des validations, lire les erreurs et retrouver d'où viennent leurs messages
- Distinguer les méthodes générées par Active Record de celles que vous écrivez
- Retrouver le fichier d'une classe à partir de son nom, sans `require`
- Rendre des seeds idempotents

## 2.1 Un atelier, plus qu'un titre

Un atelier a une description, une durée en minutes, et il n'est visible du public qu'une fois publié :

```bash
bin/rails generate migration AddDetailsToWorkshops description:text duration_minutes:integer published:boolean
```

Rails a déduit la table du **nom** de la migration (`Add...ToWorkshops`). Ouvrez-la avant de l'exécuter.

Un booléen sans valeur par défaut a trois états : `true`, `false` et `NULL`. Modifiez la migration pour que `published` vaille `false` par défaut et ne puisse pas être `NULL`. Puis :

```bash
bin/rails db:migrate
bin/rails db:migrate:status
```

Essayez `bin/rails db:rollback` puis `bin/rails db:migrate` : comment Rails sait-il défaire une migration qui ne contient qu'une méthode `change` ?

> Doc : [Active Record Migrations](https://guides.rubyonrails.org/active_record_migrations.html#creating-a-standalone-migration)

## 2.2 Validations

Ajoutez au modèle `Workshop` :

- le titre doit être **présent** et faire entre **3 et 100 caractères**
- la durée, si elle est renseignée, doit être un **entier strictement positif**

En console, testez un atelier sans titre, puis un atelier avec un titre de 2 caractères et une durée de 0, avec `valid?`, `errors.full_messages`, `save` et `save!` :

- combien d'erreurs pour l'atelier sans titre ? Pourquoi ?
- que renvoient `save` et `save!` sur un objet invalide ?

C'est la convention de l'exercice 5 : sans `!`, la méthode renvoie `false` ; avec `!`, elle lève une exception.

Les messages sont en français sans que vous ayez rien configuré : retrouvez dans `config/` le fichier des messages et la ligne qui fixe la langue par défaut.

Ajoutez enfin au modèle les méthodes `publish` et `unpublish` des exercices Ruby, telles quelles (avec `@published = true`). Elles doivent modifier l'attribut **en mémoire**, sans sauvegarder : vérifiez avec `published` et `changed?`. Que modifie `@published = true` dans un modèle ? Corrigez.

> Doc : [Active Record Validations](https://guides.rubyonrails.org/active_record_validations.html)
> Doc : [I18n - Active Record Models](https://guides.rubyonrails.org/i18n.html#active-record-models)

## 2.3 Ce que vous écrivez, ce qu'Active Record écrit pour vous

```ruby
workshop = Workshop.new(title: "Initiation à la céramique")
workshop.published?
workshop.title?
```

Vous n'avez écrit aucune de ces deux méthodes. Retrouvez qui les a définies avec `method(...).owner`, et comparez avec `workshop.method(:publish).owner`.

> Doc : [ActiveRecord::AttributeMethods::Query](https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Query.html)

## 2.4 La durée en heures et minutes

On veut afficher la durée sous la forme `1 h 30`. Ajoutez à `Workshop` une méthode `formatted_duration`, comme à l'exercice Ruby 2.6 :

- `"1 h 30"` pour 90 minutes, `"1 h"` pour 60, `"45 min"` pour 45, `"1 h 05"` pour 65
- `nil` si la durée n'est pas renseignée

Vérifiez en console, après `reload!` si elle était déjà ouverte.

**Un nom, un fichier.** Vous n'avez jamais écrit de `require` pour `Workshop` : Rails trouve le fichier grâce au nom de la classe. `Workshop` est dans `app/models/workshop.rb` ; `Registrations::Promotion` serait dans un fichier `registrations/promotion.rb`, sous l'un des dossiers de `app/`. Pour trouver une classe dans une application Rails, convertissez son nom en chemin :

```ruby
"Registrations::Promotion".underscore   # => "registrations/promotion"
```

> Doc : [Autoloading and Reloading Constants](https://guides.rubyonrails.org/autoloading_and_reloading_constants.html)

## 2.5 Seeds

Il faut des données de démonstration. Copiez le fichier de seeds fourni, puis chargez-le deux fois :

```bash
cp -r ../rails/fournis/step-02/. .
bin/rails db:seed
bin/rails db:seed
```

Comparez les deux nombres affichés, puis en console : `Workshop.where(title: "Réparer son vélo").count`.

Rendez les seeds **idempotents** : remplacez `create!` par `find_or_create_by!(title: ...)`, qui cherche l'atelier par son titre et ne le crée que s'il n'existe pas. Son bloc n'est exécuté qu'à la création : renseignez-y les autres attributs (`assign_attributes` les affecte en une fois).

Les doublons sont déjà en base. `db:reset` recrée la base depuis `db/schema.rb` et joue les seeds :

```bash
bin/rails db:reset
bin/rails db:seed
```

Le nombre affiché ne doit plus bouger. Relancez `bin/dev` (`Ctrl-C`, puis `bin/dev`) : sinon, le serveur continue de lire l'ancienne base, supprimée par `db:reset`.

Si vous modifiez la description d'un atelier dans le fichier et rejouez les seeds, que devient-elle en base ?

> Doc : [Seeds](https://guides.rubyonrails.org/active_record_migrations.html#migrations-and-seed-data)
> Doc : [find_or_create_by](https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-find_or_create_by)
