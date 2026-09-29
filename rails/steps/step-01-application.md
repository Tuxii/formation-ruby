# Step 01 - L'application et la découverte d'Active Record

> **Départ** : `origin/step-00` · **Fichiers fournis** : aucun · **Solution** : `origin/step-01`

## Objectifs

- Prendre en main l'application fournie et sa structure
- Générer un premier modèle et lire sa migration
- Découvrir les méthodes d'Active Record en console, en regardant le SQL produit
- Voir qu'un objet Active Record correspond à une ligne de la table, et que `save` écrit tout de suite

## 1.1 Récupérer l'application

Créez votre branche de travail, installez les dépendances, puis lancez le serveur :

```bash
cd workshops
git switch -c mon-travail origin/step-00
bin/setup --skip-server
bin/dev
```

Vérifiez que http://localhost:3000 affiche la page d'accueil de Rails. Laissez `bin/dev` tourner dans ce terminal et travaillez dans un second.

L'application a été créée par `rails new workshops --css=bootstrap`, avec une base vide. Les dossiers qui comptent :

| Fichier ou dossier | Ce que c'est |
| --- | --- |
| `Gemfile`, `Gemfile.lock` | les dépendances (les gems) |
| `config/routes.rb` | toutes les routes, dans un seul fichier |
| `app/models/` | les modèles |
| `app/controllers/`, `app/views/` | les contrôleurs et les vues |
| `db/migrate/` | les migrations |
| `db/schema.rb` | l'état courant du schéma, régénéré à chaque migration |
| `bin/rails` | la ligne de commande |
| `config/locales/fr.yml` | les traductions françaises |

En tête de chaque step, **Départ** et **Solution** donnent les branches correspondantes. Comparer votre code avec la solution, repartir d'une solution : `2-rails.pdf`, « Travailler avec l'application ».

> Doc : [Getting Started with Rails](https://guides.rubyonrails.org/getting_started.html)

## 1.2 Rendre les ateliers persistants

Dans les exercices Ruby, votre classe `Workshop` vivait en mémoire : relancez le programme, vos ateliers ont disparu. Il faut une table, et une classe qui sait lire et écrire dedans.

```bash
bin/rails generate model Workshop title:string
```

Ouvrez la migration **avant** de l'exécuter : que va-t-elle créer, en plus de la colonne `title` ?

```bash
bin/rails db:migrate
```

Ouvrez ensuite `db/schema.rb`. Qui a écrit ce fichier ?

> Doc : [Active Record Migrations](https://guides.rubyonrails.org/active_record_migrations.html)

## 1.3 Un modèle vide qui sait tout faire

Ouvrez `app/models/workshop.rb` : la classe est vide. Et pourtant, en console (`bin/rails console`) :

```ruby
workshop = Workshop.new(title: "Initiation à la céramique")
workshop.title
```

Où est définie la méthode `title` ? Cherchez-la avec les outils d'introspection de l'exercice 6 :

```ruby
Workshop.instance_methods(false)
workshop.method(:title).owner
Workshop.column_names
```

D'où viennent les attributs d'un modèle Active Record, et à quel moment sont-ils connus ?

> Doc : [Active Record Basics](https://guides.rubyonrails.org/active_record_basics.html)

## 1.4 Créer, retrouver, supprimer

L'application devra retrouver un atelier par son id (dans une URL) ou par son titre (dans une recherche), et réagir quand il n'existe pas. En console, lisez la requête SQL affichée sous chaque appel :

- Créez un atelier avec `Workshop.new(title: "...")`, puis `save`. Que vaut `id` avant et après ?
- Retrouvez-le avec `find`, puis avec `find_by(title: ...)`, pour une valeur qui existe puis pour une qui n'existe pas. Quand utiliser l'un ou l'autre ?
- Cherchez-le avec `where(title: ...)`. Que renvoie `where` ? Regardez `.class`. Tapez ensuite `relation = Workshop.where(title: "..."); nil` : pourquoi aucune requête cette fois ?
- Créez un second atelier, appelez `destroy` dessus, puis `reload`. L'objet Ruby existe-t-il encore ?

> Doc : [Active Record Query Interface](https://guides.rubyonrails.org/active_record_querying.html)

## 1.5 `save` écrit tout de suite

Modifiez un atelier en console :

```ruby
workshop = Workshop.first
workshop.title = "Titre modifié"
workshop.changed?
workshop.changes
workshop.save
```

Lisez les logs : quelle requête `save` a-t-il envoyée, et quelles colonnes contient-elle ?

C'est la classe (`Workshop.find`) et l'objet lui-même (`workshop.save`) qui parlent à la base : un objet `Workshop` correspond à une ligne de la table `workshops`.

> Doc : [Active Record Basics - Active Record Pattern](https://guides.rubyonrails.org/active_record_basics.html#the-active-record-pattern)
> Doc : [Dirty tracking](https://api.rubyonrails.org/classes/ActiveModel/Dirty.html)
