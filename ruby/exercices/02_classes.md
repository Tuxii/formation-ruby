# Exercice 2 - Les classes

Écrivez dans `02_classes.rb`, lancez avec `ruby 02_classes.rb`. Support : `1-ruby.pdf`, section 2.

Un hash n'empêche pas d'écrire `session[:capcity]` ou le statut `:publish` au lieu de `:published`. On passe aux objets.

Comme à l'exercice 1, une ligne qui lève une erreur arrête le script : lisez le message, puis commentez la ligne.

## 2.1 La classe Session (à la main)

Créez une classe `Session` avec un `initialize(title, capacity)` qui remplit `@title`, `@capacity`, `@status = :draft` et `@registrants = []`.

Écrivez les méthodes de lecture et d'écriture **à la main**, sans `attr_reader` ni `attr_accessor` : `capacity` en lecture et écriture, `title`, `status` et `registrants` en lecture seule.

```ruby
session = Session.new("Initiation à la céramique", 12)
puts session.title          # => Initiation à la céramique
session.capacity = 14
puts session.capacity       # => 14
session.capacity=(15)
puts session.capacity       # => 15
p session.status            # => :draft
p session                   # que voyez-vous ?
session.status = :published # => NoMethodError
```

- `session.capacity=(15)` fonctionne. Qu'est-ce que ça vous apprend sur `session.capacity = 14` ?
- Quel est le nom exact de la méthode introuvable dans le message de la `NoMethodError` ?

> Doc : [Class#new](https://docs.ruby-lang.org/en/4.0/Class.html#method-i-new)
> Doc : [Instance variables](https://docs.ruby-lang.org/en/4.0/syntax/assignment_rdoc.html#label-Instance+Variables)
> Doc : [Method names](https://docs.ruby-lang.org/en/4.0/syntax/methods_rdoc.html#label-Method+Names)

## 2.2 Refacto avec attr_reader / attr_accessor

Avant de toucher au code, lancez ces deux lignes et notez le résultat : les méthodes de votre classe, et l'endroit où `title` est définie.

```ruby
p Session.instance_methods(false).sort
p Session.instance_method(:title).source_location
```

Remplacez ensuite vos méthodes écrites à la main par `attr_reader :title, :status, :registrants` et `attr_accessor :capacity`. Relancez.

Comparez les deux listes. Vers quelle ligne pointe `source_location` avant la refacto ? Et après ?

> Doc : [Module#attr_reader](https://docs.ruby-lang.org/en/4.0/Module.html#method-i-attr_reader)
> Doc : [Module#attr_accessor](https://docs.ruby-lang.org/en/4.0/Module.html#method-i-attr_accessor)
> Doc : [Module#instance_methods](https://docs.ruby-lang.org/en/4.0/Module.html#method-i-instance_methods)
> Doc : [Module#instance_method](https://docs.ruby-lang.org/en/4.0/Module.html#method-i-instance_method)
> Doc : [UnboundMethod#source_location](https://docs.ruby-lang.org/en/4.0/UnboundMethod.html#method-i-source_location)

## 2.3 Prédicats et calculs

Ajoutez à `Session` :

- `remaining_seats` : la capacité moins le nombre d'inscrits
- `full?` : `true` s'il ne reste plus de place
- `published?` : `true` si le statut est `:published`

```ruby
bread = Session.new("Pain au levain", 8)
puts bread.remaining_seats   # => 8
puts bread.full?             # => false
puts bread.published?        # => false
```

Dans `remaining_seats`, pourquoi `capacity` tout seul suffit-il, sans `@capacity` ni `self.capacity` ?

> Doc : [Receiver](https://docs.ruby-lang.org/en/4.0/syntax/calling_methods_rdoc.html#label-Receiver)

## 2.4 Méthodes d'action

**`publish`** passe le statut à `:published`. Le statut doit rester en lecture seule depuis l'extérieur. Dans l'ordre :

1. Écrivez `status = :published` dans `publish`. Que vaut `session.status` après `session.publish` ? Pourquoi ?
2. Remplacez par `self.status = :published`. Que se passe-t-il ?
3. Trouvez deux façons de faire qui marchent : l'une passe par la variable d'instance, l'autre par un setter privé.

```ruby
session = Session.new("Aquarelle en plein air", 3)
session.publish
p session.status                # => :published
session.status = :cancelled     # => NoMethodError (toujours en lecture seule)
```

**`register(name)`** ajoute un inscrit et renvoie `true`, ou renvoie `false` si la session est complète ou si la personne est déjà inscrite. Cette dernière vérification va dans une méthode **privée** `already_registered?(name)`.

**`to_s`** renvoie par exemple `"Aquarelle en plein air [published] 2/3 places libres"`.

```ruby
puts session.register("David")         # => true
puts session.register("David")         # => false (déjà inscrit)
puts session                           # => Aquarelle en plein air [published] 2/3 places libres
puts session.register("Emma")          # => true
puts session.register("Fanny")         # => true
puts session.register("Gaëlle")        # => false (complète)
session.already_registered?("David")   # => NoMethodError (méthode privée)
```

Pourquoi `puts session` affiche-t-il votre texte et pas `#<Session:0x...>` ?

La session est complète. Essayez pourtant :

```ruby
session.registrants << "Intrus"
puts session
```

Comment `Intrus` est-il entré sans passer par `register` ?

> Doc : [Assignment methods](https://docs.ruby-lang.org/en/4.0/syntax/assignment_rdoc.html#label-Assignment+Methods)
> Doc : [Visibility](https://docs.ruby-lang.org/en/4.0/syntax/modules_and_classes_rdoc.html#label-Visibility)
> Doc : [Object#to_s](https://docs.ruby-lang.org/en/4.0/Object.html#method-i-to_s)

## 2.5 Méthode de classe

Ajoutez une méthode de classe `Session.statuses` qui renvoie `[:draft, :published, :full, :cancelled, :finished]`.

```ruby
p Session.statuses
p session.statuses        # que se passe-t-il ?
p session.class.statuses
```

> Doc : [Method scope (def self.)](https://docs.ruby-lang.org/en/4.0/syntax/methods_rdoc.html#label-Scope)
> Doc : [Kernel#class](https://docs.ruby-lang.org/en/4.0/Kernel.html#method-i-class)

## 2.6 La classe Workshop

Une session, c'est une date et une salle ; ce qu'on y fait, c'est l'atelier. Créez une classe `Workshop` avec :

- un `initialize(title, duration_minutes:, description: "")`
- `title` en lecture seule, `description` et `duration_minutes` en lecture et écriture
- `@published` à `false` à l'initialisation, `published?` et `publish`
- `formatted_duration` : `"1 h 30"` pour 90 minutes, `"2 h"` pour 120, `"45 min"` pour 45, `"1 h 05"` pour 65 (regardez `Integer#divmod` et `String#rjust`)
- `to_s` : `"Initiation à la céramique (1 h 30)"`

```ruby
workshop = Workshop.new("Initiation à la céramique", duration_minutes: 90)
workshop.description = "Modeler, tourner, émailler, et repartir avec son bol."
puts workshop                  # => Initiation à la céramique (1 h 30)
puts workshop.published?       # => false
workshop.publish
puts workshop.published?       # => true
puts Workshop.new("Pain au levain", duration_minutes: 120).formatted_duration    # => 2 h
puts Workshop.new("Croquis express", duration_minutes: 45).formatted_duration    # => 45 min
puts Workshop.new("Reliure japonaise", duration_minutes: 65).formatted_duration  # => 1 h 05
Workshop.new("Croquis express")   # => ArgumentError (missing keyword: :duration_minutes)
```

> Doc : [Keyword arguments](https://docs.ruby-lang.org/en/4.0/syntax/methods_rdoc.html#label-Keyword+Arguments)
> Doc : [Integer#divmod](https://docs.ruby-lang.org/en/4.0/Integer.html#method-i-divmod)
> Doc : [String#rjust](https://docs.ruby-lang.org/en/4.0/String.html#method-i-rjust)

## 2.7 Un atelier programme ses sessions

Un atelier a plusieurs sessions. On veut écrire :

```ruby
ceramics = Workshop.new("Initiation à la céramique", duration_minutes: 90)
saturday = ceramics.schedule(capacity: 6, starts_at: Time.new(2026, 10, 10, 9, 30))
tuesday = ceramics.schedule(capacity: 4, starts_at: Time.new(2026, 10, 13, 18, 30))

puts ceramics.sessions.size                        # => 2
puts ceramics.total_seats                          # => 10
puts saturday                                      # => Initiation à la céramique [draft] 6/6 places libres
puts saturday.workshop                             # => Initiation à la céramique (1 h 30)
puts saturday.starts_at.strftime("%d/%m à %Hh%M")  # => 10/10 à 09h30
```

Pour ça :

- `Workshop` a un tableau `@sessions`, vide au départ, lisible avec `sessions`
- `Session` accepte deux keyword arguments optionnels, `workshop:` et `starts_at:` (par défaut `nil`), lisibles avec `workshop` et `starts_at`. Vos tests précédents doivent continuer à passer.
- `schedule(capacity:, starts_at:)` crée une `Session` qui porte le titre de l'atelier et **connaît son atelier**, la range dans `@sessions` et la renvoie. Comment désignez-vous l'atelier lui-même dans `schedule` ?
- `total_seats` renvoie la somme des capacités des sessions (avec `each` et une variable, comme au 1.8)

> Doc : [self](https://docs.ruby-lang.org/en/4.0/syntax/modules_and_classes_rdoc.html#label-self)
> Doc : [Time#strftime](https://docs.ruby-lang.org/en/4.0/Time.html#method-i-strftime)
