# Step 09 - Scopes et filtres

> **Départ** : la fin du step 08 (ou `origin/step-08`) · **Fichiers fournis** : au 9.3 · **Solution** : `origin/step-09`

## Objectifs

- Donner un nom à une requête avec un scope, et enchaîner les scopes
- Filtrer une liste à partir des paramètres de l'URL
- Repérer une requête répétée à chaque ligne, et la supprimer avec `includes`

## 9.1 Un premier scope

La page d'accueil compte les ateliers publiés avec `Workshop.where(published: true)`. Donnons un nom à cette requête. Dans `Workshop` :

```ruby
scope :published, -> { where(published: true) }
```

Utilisez-le dans `PagesController#home` : `Workshop.published.count`.

Un scope est une méthode de classe qui renvoie une requête. Il se lit comme une phrase et s'écrit une seule fois.

> Doc : [Scopes](https://guides.rubyonrails.org/active_record_querying.html#scopes)

## 9.2 Les scopes des sessions

Dans `Session` :

```ruby
scope :upcoming, -> { where(starts_at: Time.current..) }
```

`Time.current..` est un intervalle sans fin : « à partir de maintenant ».

**À vous.** Écrivez le scope `past`, les sessions déjà commencées : l'intervalle sans début s'écrit `...Time.current`. Testez en console, puis enchaînez avec les scopes que l'`enum` a générés :

```ruby
Session.upcoming.count
Session.past.count
Session.upcoming.published.count
puts Session.upcoming.published.to_sql
```

Chaque scope ajoute une condition. La requête ne part qu'au moment où on a besoin du résultat (`count`, une boucle, l'affichage) : jusque-là, c'est un objet `ActiveRecord::Relation` qu'on peut encore compléter.

Un scope peut prendre un argument. Ajoutez :

```ruby
scope :with_status, ->(status) { where(status: status) if status.present? }
```

Quand la condition est fausse, le bloc renvoie `nil`, et le scope renvoie alors toutes les lignes : on peut enchaîner sans vérifier chaque filtre. Essayez `Session.with_status(nil).count` et `Session.with_status("draft").count`.

**À vous.** Sur le même modèle, écrivez `for_workshop(workshop_id)`, qui filtre sur la colonne `workshop_id`. Vérifiez : `Session.for_workshop(1).count` et `Session.for_workshop("").count`.

## 9.3 Filtrer la liste des sessions

Copiez le formulaire de filtres et la liste qui l'affiche :

```bash
cp -r ../rails/fournis/step-09/. .
```

Le formulaire envoie une requête **GET** : les filtres apparaissent dans l'URL, qu'on peut copier et partager. Filtrez une fois sur http://localhost:3000/sessions et lisez l'URL : la liste ne change pas encore, le contrôleur ignore ces paramètres.

Dans `SessionsController#index`, le premier filtre : la case « À venir » envoie `upcoming=1` quand elle est cochée.

```ruby
def index
  @sessions = Session.order(:starts_at)
  @sessions = @sessions.upcoming if params[:upcoming] == "1"
end
```

**À vous.** Ajoutez les deux autres filtres, avec `params[:status]` et `params[:workshop_id]` et les scopes du 9.2. Essayez plusieurs combinaisons dans le navigateur.

> Doc : [Form Helpers - A Generic Search Form](https://guides.rubyonrails.org/form_helpers.html#a-generic-search-form)

## 9.4 Une requête par ligne

Affichez toutes les sessions et lisez le log du serveur pour cette requête : un `SELECT` sur `sessions`, puis un `SELECT` sur `workshops` pour chaque ligne du tableau, parfois marqué `CACHE`. Le partial `_session` affiche `session.workshop.title` : chaque ligne charge son atelier.

C'est le problème du **N+1** : une requête pour la liste, puis une par ligne. Invisible avec une quinzaine de sessions, coûteux avec 3 000.

Chargez les ateliers en même temps que les sessions :

```ruby
@sessions = Session.includes(:workshop).order(:starts_at)
```

Rechargez : les `SELECT` répétés sur `workshops` sont remplacés par un seul, qui charge tous les ateliers de la liste en une fois (`WHERE id IN (...)`).

> Doc : [N+1 Queries Problem](https://guides.rubyonrails.org/active_record_querying.html#n-1-queries-problem)
> Doc : [Eager Loading Associations](https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations)
