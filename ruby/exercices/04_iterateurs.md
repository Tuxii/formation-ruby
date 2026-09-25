# Exercice 4 - Blocs, itérateurs et Enumerable

Écrivez dans `04_iterateurs.rb`, lancez avec `ruby 04_iterateurs.rb`. Support : `1-ruby.pdf`, section 4.

Recopiez d'abord vos modules et vos classes de l'exercice 3 (ou ceux de la correction), sans les tests.

Jusqu'ici, un inscrit était un simple nom. Une vraie inscription a un participant, un statut, une date : on passe à des objets.

## Données de travail

Copiez ces deux classes à la suite des vôtres :

```ruby
class Participant
  attr_reader :name, :email

  def initialize(name, email)
    @name = name
    @email = email
  end

  def to_s
    "#{name} <#{email}>"
  end
end

class Registration
  attr_reader :participant, :session, :status, :registered_at

  def initialize(participant, session, status, registered_at)
    @participant = participant
    @session = session
    @status = status
    @registered_at = registered_at
  end

  def confirmed?
    status == :confirmed
  end

  def waitlisted?
    status == :waitlisted
  end

  def cancelled?
    status == :cancelled
  end

  def to_s
    "#{participant.name} (#{status})"
  end
end
```

Dans `Session`, ajoutez `attr_reader :registrations` et `@registrations = []` dans `initialize`. `@registrants` reste pour l'instant : on fait le ménage en 4.6.

Puis les données (vous pouvez copier-coller) :

```ruby
ceramics = Workshop.new("Initiation à la céramique", duration_minutes: 180)
watercolor = Workshop.new("Aquarelle en plein air", duration_minutes: 120)

saturday = ceramics.schedule(capacity: 5, starts_at: Time.new(2026, 10, 10, 9, 30))
tuesday = ceramics.schedule(capacity: 4, starts_at: Time.new(2026, 10, 13, 18, 30))
sunday = watercolor.schedule(capacity: 3, starts_at: Time.new(2026, 10, 11, 14, 0))

alice = Participant.new("Alice Martin", "alice@exemple.fr")
bruno = Participant.new("Bruno Petit", "bruno@exemple.com")
chloe = Participant.new("Chloé Durand", "chloe@exemple.fr")
david = Participant.new("David Leroy", "david@exemple.com")
emma = Participant.new("Emma Moreau", "emma@exemple.fr")
fanny = Participant.new("Fanny Bertin", "fanny@exemple.com")
gaelle = Participant.new("Gaëlle Roux", "gaelle@exemple.fr")
hugo = Participant.new("Hugo Lambert", "hugo@exemple.com")

registrations = [
  Registration.new(alice, saturday, :confirmed, Time.new(2026, 9, 1, 9, 12)),
  Registration.new(bruno, saturday, :confirmed, Time.new(2026, 9, 1, 12, 40)),
  Registration.new(chloe, saturday, :confirmed, Time.new(2026, 9, 2, 8, 5)),
  Registration.new(david, saturday, :cancelled, Time.new(2026, 9, 2, 21, 30)),
  Registration.new(emma, saturday, :confirmed, Time.new(2026, 9, 3, 10, 0)),
  Registration.new(fanny, saturday, :confirmed, Time.new(2026, 9, 4, 18, 45)),
  Registration.new(gaelle, saturday, :waitlisted, Time.new(2026, 9, 5, 7, 55)),
  Registration.new(david, tuesday, :confirmed, Time.new(2026, 9, 3, 9, 0)),
  Registration.new(hugo, tuesday, :confirmed, Time.new(2026, 9, 6, 14, 20)),
  Registration.new(alice, sunday, :confirmed, Time.new(2026, 9, 2, 13, 10)),
  Registration.new(chloe, sunday, :confirmed, Time.new(2026, 9, 2, 13, 15)),
  Registration.new(emma, sunday, :cancelled, Time.new(2026, 9, 3, 11, 30)),
  Registration.new(hugo, sunday, :confirmed, Time.new(2026, 9, 4, 9, 0)),
  Registration.new(bruno, sunday, :waitlisted, Time.new(2026, 9, 5, 16, 0))
]

registrations.each { |registration| registration.session.registrations << registration }
```

Pour afficher une inscription, utilisez `puts` (qui appelle `to_s`) plutôt que `p` : `p` affiche aussi sa session, son atelier et toutes leurs inscriptions.

## 4.1 each et map

- Prédisez, puis vérifiez avec `p` : que renvoie `[1, 2, 3].each { |n| n * 10 }` ? Et `[1, 2, 3].map { |n| n * 10 }` ?
- Créez un tableau `lines` de chaînes du type `"Alice Martin, 01/09 à 09h12"`, une par inscription, et affichez-le avec `puts`.

> Doc : [Array#each](https://docs.ruby-lang.org/en/4.0/Array.html#method-i-each)
> Doc : [Enumerable#map](https://docs.ruby-lang.org/en/4.0/Enumerable.html#method-i-map)
> Doc : [Time#strftime](https://docs.ruby-lang.org/en/4.0/Time.html#method-i-strftime)

## 4.2 Chercher

Cherchez avec `find` la première inscription d'une participante dont le nom commence par `Inès` (`start_with?`). Que renvoie `find` quand rien ne correspond ?

Affichez ensuite le nom de la participante avec `&.`, ou `Aucune inscription pour Inès` si rien n'est trouvé. Combien de `&.` faut-il ?

> Doc : [Enumerable#find](https://docs.ruby-lang.org/en/4.0/Enumerable.html#method-i-find)
> Doc : [Safe navigation operator](https://docs.ruby-lang.org/en/4.0/syntax/calling_methods_rdoc.html#label-Safe+Navigation+Operator)

## 4.3 Calculer et regrouper

- Réécrivez `Workshop#total_seats`, la boucle du 2.7, en une ligne avec `sum` : `ceramics.total_seats` vaut `9`.
- Le nombre d'inscriptions par statut, sous la forme `{confirmed: 10, cancelled: 2, waitlisted: 2}` : d'abord avec `each_with_object` (indice : `Hash.new(0)`), puis avec la méthode de `1-ruby.pdf`, section 4, qui fait exactement ça.
- Les inscriptions regroupées par session, avec `group_by`. Tableau ou hash ? Parcourez le résultat pour afficher une ligne par session : `Initiation à la céramique, le 10/10 : 7 inscriptions`.

> Doc : [Enumerable](https://docs.ruby-lang.org/en/4.0/Enumerable.html)
> Doc : [Enumerable#each_with_object](https://docs.ruby-lang.org/en/4.0/Enumerable.html#method-i-each_with_object)
> Doc : [Hash.new](https://docs.ruby-lang.org/en/4.0/Hash.html#method-c-new)
> Doc : [Enumerable#group_by](https://docs.ruby-lang.org/en/4.0/Enumerable.html#method-i-group_by)
> Doc : [Hash#each](https://docs.ruby-lang.org/en/4.0/Hash.html#method-i-each)

## 4.4 Chaîner, pour répondre à des questions métier

En une chaîne d'appels à chaque fois :

- Les noms des participants qui ont au moins deux inscriptions non annulées, par ordre alphabétique : `["Alice Martin", "Bruno Petit", "Chloé Durand", "Hugo Lambert"]`. Que renvoie chaque étape : un tableau ou un hash ?
- Toutes les inscriptions de l'atelier céramique, à travers ses sessions (indice : `flat_map`) : il y en a 9. Puis les noms distincts des participants concernés : 8 noms.

> Doc : [Chaining method calls](https://docs.ruby-lang.org/en/4.0/syntax/calling_methods_rdoc.html#label-Chaining+Method+Calls)
> Doc : [Hash#select](https://docs.ruby-lang.org/en/4.0/Hash.html#method-i-select)
> Doc : [Enumerable#flat_map](https://docs.ruby-lang.org/en/4.0/Enumerable.html#method-i-flat_map)
> Doc : [Enumerable#uniq](https://docs.ruby-lang.org/en/4.0/Enumerable.html#method-i-uniq)

## 4.5 Trois méthodes qui se ressemblent

Le responsable des ateliers veut trois listes par session : les confirmés, la liste d'attente, les annulés. La première est écrite, ajoutez-la à `Session` :

```ruby
def confirmed_registrations
  result = []
  registrations.each do |registration|
    result << registration if registration.confirmed?
  end
  result
end
```

Écrivez `waitlisted_registrations` sur le même modèle, sans `select`.

```ruby
p saturday.confirmed_registrations.size    # => 5
p saturday.waitlisted_registrations.size   # => 1
```

Un seul mot change. Et les demandes suivantes ne portent même plus sur le statut : les inscriptions faites avant le 3 septembre, celles dont l'email se termine par `.fr`. Ce qui varie, c'est **le critère**, c'est-à-dire du code.

**Étape 1.** Écrivez `Session#filter_registrations`, qui passe chaque inscription au bloc avec `yield` et garde celles pour lesquelles le bloc renvoie une valeur truthy. Réécrivez `confirmed_registrations` et `waitlisted_registrations` en une ligne chacune, et ajoutez `cancelled_registrations`.

```ruby
p saturday.cancelled_registrations.size    # => 1

before_the_3rd = saturday.filter_registrations { |r| r.registered_at < Time.new(2026, 9, 3) }
p before_the_3rd.map { |r| r.participant.name }
# => ["Alice Martin", "Bruno Petit", "Chloé Durand", "David Leroy"]

dot_fr = saturday.filter_registrations { |r| r.participant.email.end_with?(".fr") }
p dot_fr.map { |r| r.participant.name }
# => ["Alice Martin", "Chloé Durand", "Emma Moreau", "Gaëlle Roux"]
```

**Étape 2.** Votre `filter_registrations` refait `select` à la main. Réécrivez-le en récupérant le bloc dans un paramètre `&criterion`, et en le **transmettant** tel quel à `registrations.select`. Vos tests doivent toujours passer.

> Doc : [Block argument](https://docs.ruby-lang.org/en/4.0/syntax/methods_rdoc.html#label-Block+Argument)

## 4.6 Une session qui se parcourt

On voudrait écrire `saturday.count` ou `saturday.min_by { ... }` directement, comme si la session était une collection.

Incluez `Enumerable` dans `Session`. Son seul prérequis : la classe doit définir `each`. Écrivez `Session#each`, qui transmet le bloc reçu à `registrations.each` (même principe que dans `1-ruby.pdf`, section 4).

```ruby
p saturday.count                                             # => 7
p saturday.map { |r| r.participant.name }.first(3)           # => ["Alice Martin", "Bruno Petit", "Chloé Durand"]
p saturday.min_by { |r| r.registered_at }.participant.name   # => "Alice Martin"
```

Combien de méthodes avez-vous gagnées en écrivant `each` ? Affichez `Enumerable.instance_methods.size`.

`saturday.count` vaut 7 alors que 5 places seulement sont prises : la session se parcourt comme toutes ses inscriptions. En Rails, c'est l'association qui se parcourt : `session.registrations.each { ... }`.

Maintenant, le ménage promis :

- réécrivez `remaining_seats` avec `count` : seules les inscriptions **confirmées** occupent une place
- remplacez `register(name)` par `register(participant)` : il renvoie `false` si la session est complète ou si le participant y a déjà une inscription non annulée ; sinon, il ajoute à `registrations` une `Registration` confirmée, datée de `Time.now`, et renvoie `true`
- réécrivez `already_registered?(participant)` avec `any?`
- supprimez `@registrants` et son `attr_reader`

```ruby
puts saturday   # => Initiation à la céramique [draft] 0/5 places libres
puts tuesday    # => Initiation à la céramique [draft] 2/4 places libres
ines = Participant.new("Inès Garnier", "ines@exemple.fr")
puts tuesday.register(ines)    # => true
puts tuesday.register(ines)    # => false
puts saturday.register(ines)   # => false
puts tuesday    # => Initiation à la céramique [draft] 1/4 places libres
```

> Doc : [Enumerable usage](https://docs.ruby-lang.org/en/4.0/Enumerable.html#module-Enumerable-label-Usage)
> Doc : [Enumerable#count](https://docs.ruby-lang.org/en/4.0/Enumerable.html#method-i-count)
> Doc : [Enumerable#any?](https://docs.ruby-lang.org/en/4.0/Enumerable.html#method-i-any-3F)

## 4.7 &:symbole, Proc et lambda (démo)

À écrire à la suite de votre fichier ; on les explore ensemble.

```ruby
p registrations.map(&:status).first(3)      # => [:confirmed, :confirmed, :confirmed]
p registrations.count(&:confirmed?)          # => 10

confirmed_check = :confirmed?.to_proc
p confirmed_check.call(registrations.first)   # => true
```

- Stockez un critère dans une variable, puis passez-le à plusieurs méthodes :

```ruby
early_bird = Proc.new { |r| r.registered_at < Time.new(2026, 9, 2) }
p registrations.count(&early_bird)                  # => 2
p saturday.filter_registrations(&early_bird).size   # => 2
```

- Créez une lambda `rate = ->(session) { ... }` qui renvoie le taux de remplissage d'une session en pourcentage entier (inscriptions confirmées × 100 / capacité) : `rate.call(tuesday)` vaut `75`. Appelez-la avec deux arguments : que se passe-t-il ? Et avec la même chose écrite en `Proc.new`, nommée `rate_proc` ?

En Rails, vous croiserez des lambdas partout :

```ruby
scope :confirmed, -> { where(status: :confirmed) }
```

> Doc : [Symbol#to_proc](https://docs.ruby-lang.org/en/4.0/Symbol.html#method-i-to_proc)
> Doc : [Proc to block conversion](https://docs.ruby-lang.org/en/4.0/syntax/calling_methods_rdoc.html#label-Proc+to+Block+Conversion)
> Doc : [Lambda and non-lambda semantics](https://docs.ruby-lang.org/en/4.0/Proc.html#class-Proc-label-Lambda+and+non-lambda+semantics)
