# Exercice 1 - Les bases de Ruby

Écrivez dans `01_bases.rb`, lancez avec `ruby 01_bases.rb`. Support : `1-ruby.pdf`, section 1, à lire après le 1.1.

Certaines lignes lèvent volontairement une erreur, qui arrête le script : lisez le message, puis commentez la ligne pour que la suite s'exécute.

## 1.1 Combien reste-t-il de places ?

Copiez cette session dans votre fichier :

```ruby
session = {
  title: "Initiation à la céramique",
  capacity: 12,
  registrants: ["Alice", "Bruno", "Chloé"],
  status: :published
}
```

Écrivez une méthode `remaining_seats(session)` qui renvoie la capacité moins le nombre d'inscrits. Deux briques de syntaxe pour démarrer :

```ruby
session[:title]   # => "Initiation à la céramique"

def method_name(argument)
  # ...
end
```

Vérifiez :

```ruby
puts remaining_seats(session)   # => 9
```

- Si vous avez écrit `return`, enlevez-le. Ça marche toujours ? Pourquoi ?
- Appelez `remaining_seats` sur une session sans clé `:registrants` et lisez l'erreur (vous la corrigerez au 1.4) :

```ruby
new_session = { title: "Pain au levain", capacity: 8, status: :draft }
remaining_seats(new_session)
```

Commentez ensuite l'appel qui plante, mais gardez la ligne `new_session = ...` : cette session resservira aux 1.4 et 1.6.

> Doc : [Hash literals](https://docs.ruby-lang.org/en/4.0/syntax/literals_rdoc.html#label-Hash+Literals)
> Doc : [Return values](https://docs.ruby-lang.org/en/4.0/syntax/methods_rdoc.html#label-Return+Values)
> Doc : [NoMethodError](https://docs.ruby-lang.org/en/4.0/NoMethodError.html)

## 1.2 Types et symboles

Copiez et lancez :

```ruby
status = :published
instructor = nil

puts "#{status} est un #{status.class}"
puts "#{instructor} est un #{instructor.class}"
```

- Pourquoi le deux-points de `:published` disparaît-il, et pourquoi `instructor` n'affiche-t-il rien ? Quelle méthode l'interpolation appelle-t-elle ?
- Affichez `true.class` et `false.class`. Existe-t-il une classe `Boolean` en Ruby ?

> Doc : [String literals](https://docs.ruby-lang.org/en/4.0/syntax/literals_rdoc.html#label-String+Literals)
> Doc : [NilClass#to_s](https://docs.ruby-lang.org/en/4.0/NilClass.html#method-i-to_s)
> Doc : [Symbol](https://docs.ruby-lang.org/en/4.0/Symbol.html)
> Doc : [TrueClass](https://docs.ruby-lang.org/en/4.0/TrueClass.html)

## 1.3 Chaînes de caractères

```ruby
title = "Initiation à la céramique"
p title.length
p title.upcase
```

**Le piège du `!`.** Prédisez ce qu'affiche ce code, puis vérifiez :

```ruby
title = "Initiation à la céramique"
label = title
p title.upcase!
p label
p title.upcase!
```

- Pourquoi `label` a-t-il changé ? En PHP, `$label = $title;` copie la chaîne. Que copie `label = title` en Ruby ?
- Pourquoi le second `upcase!` renvoie-t-il `nil` ? Essayez `title.upcase!.length` et lisez l'erreur.

> Doc : [String#length](https://docs.ruby-lang.org/en/4.0/String.html#method-i-length)
> Doc : [String#upcase!](https://docs.ruby-lang.org/en/4.0/String.html#method-i-upcase-21)

## 1.4 Hash : lire sans se faire piéger

Avec la `session` du 1.1, affichez avec `p` :

- `session[:instructor]`, puis `session.fetch(:instructor)` : quelle différence pour une clé absente ?
- `session.fetch(:instructor, "à définir")`
- `session["title"]` : pourquoi `nil` ?
- `session[:instructor]&.upcase`, puis `session[:title]&.upcase` : à quoi sert `&.` ?

Redéfinissez ensuite `remaining_seats` dans la section 1.4 de votre fichier (la dernière définition remplace la précédente) : une session sans clé `:registrants` n'a aucun inscrit.

```ruby
puts remaining_seats(session)       # => 9
puts remaining_seats(new_session)   # => 8
```

> Doc : [Hash#fetch](https://docs.ruby-lang.org/en/4.0/Hash.html#method-i-fetch)
> Doc : [Hash: Key not found?](https://docs.ruby-lang.org/en/4.0/Hash.html#class-Hash-label-Key+Not+Found-3F)
> Doc : [Safe navigation operator](https://docs.ruby-lang.org/en/4.0/syntax/calling_methods_rdoc.html#label-Safe+Navigation+Operator)

## 1.5 Une méthode de formatage

Écrivez `format_session(session, with_seats: true)`, qui renvoie une ligne avec le statut en majuscules et réutilise `remaining_seats` :

```ruby
puts format_session(session)
# => Initiation à la céramique [PUBLISHED] 9 places restantes

puts format_session(session, with_seats: false)
# => Initiation à la céramique [PUBLISHED]
```

- Appelez `format_session(session, false)` et lisez l'erreur : que vous apprend-elle sur les keyword arguments ?
- (bonus) `1 place restante` au singulier :

```ruby
puts format_session({ title: "Reliure japonaise", capacity: 1, registrants: [], status: :published })
# => Reliure japonaise [PUBLISHED] 1 place restante
```

> Doc : [Keyword arguments](https://docs.ruby-lang.org/en/4.0/syntax/methods_rdoc.html#label-Keyword+Arguments)
> Doc : [ArgumentError](https://docs.ruby-lang.org/en/4.0/ArgumentError.html)
> Doc : [Ternary if](https://docs.ruby-lang.org/en/4.0/syntax/control_expressions_rdoc.html#label-Ternary+if)

## 1.6 Méthodes prédicats

Écrivez trois méthodes :

- `full?(session)` : `true` s'il ne reste plus de place
- `published?(session)` : `true` si le statut est `:published`
- `open?(session)` : `true` si la session est publiée **et** pas complète

```ruby
watercolor = { title: "Aquarelle en plein air", capacity: 3, registrants: ["David", "Emma", "Fanny"], status: :published }

puts full?(session)             # => false
puts full?(watercolor)          # => true
puts published?(new_session)    # => false
puts open?(session)             # => true
puts open?(watercolor)          # => false
```

> Doc : [Method names](https://docs.ruby-lang.org/en/4.0/syntax/methods_rdoc.html#label-Method+Names)
> Doc : [Logical operators](https://docs.ruby-lang.org/en/4.0/syntax/operators_rdoc.html#label-Logical+Operators)

## 1.7 Truthiness

Prédisez ce qu'affiche ce code **avant** de le lancer, puis vérifiez. Lesquelles de ces quatre conditions seraient fausses en PHP ?

```ruby
puts "la chaîne \"0\" est vraie" if "0"
puts "0.0 est vrai" if 0.0
puts "un hash vide est vrai" if {}
puts "la chaîne \"false\" est vraie" if "false"
```

Ruby affiche `warning: string literal in condition`, en tête de la sortie, pour deux lignes : il a repéré une condition toujours vraie.

Copiez cette méthode écrite par un collègue, et `sourdough`. Testez-la sur `session`, puis sur `sourdough` :

```ruby
def has_registrants?(session)
  if session.fetch(:registrants, [])
    true
  else
    false
  end
end

sourdough = { title: "Pain au levain", capacity: 8, registrants: [], status: :draft }
```

Expliquez le bug, puis réécrivez la méthode sans `if ... true else false` :

```ruby
puts has_registrants?(session)     # => true
puts has_registrants?(sourdough)   # => false
```

> Doc : [Boolean and nil literals](https://docs.ruby-lang.org/en/4.0/syntax/literals_rdoc.html#label-Boolean+and+Nil+Literals)
> Doc : [Modifier if and unless](https://docs.ruby-lang.org/en/4.0/syntax/control_expressions_rdoc.html#label-Modifier+if+and+unless)
> Doc : [Array#any?](https://docs.ruby-lang.org/en/4.0/Array.html#method-i-any-3F)

## 1.8 Plusieurs sessions

Copiez ce tableau :

```ruby
sessions = [
  { title: "Initiation à la céramique", capacity: 12, registrants: ["Alice", "Bruno", "Chloé"], status: :published },
  { title: "Aquarelle en plein air", capacity: 3, registrants: ["David", "Emma", "Fanny"], status: :published },
  { title: "Pain au levain", capacity: 8, registrants: [], status: :draft },
  { title: "Photo de rue", capacity: 10, registrants: ["Gaëlle", "Hugo"], status: :cancelled }
]
```

Pour parcourir un tableau, passez un bloc à `each`. `each` et `if` suffisent ici (`select` et `sum` arrivent à l'exercice 4).

```ruby
sessions.each do |session|
  # session désigne tour à tour chaque élément du tableau
end
```

- Affichez chaque session avec `format_session`.
- Affichez uniquement les sessions ouvertes aux inscriptions (avec `open?`).
- Écrivez `open_remaining_seats(sessions)`, qui renvoie le total des places restantes dans les sessions ouvertes : `9`.
- Ajoutez avec `<<` une session `Reliure japonaise` (6 places, aucun inscrit, publiée), puis réaffichez les sessions ouvertes et `open_remaining_seats(sessions)` : `15`.

> Doc : [Array#each](https://docs.ruby-lang.org/en/4.0/Array.html#method-i-each)
> Doc : [Block argument](https://docs.ruby-lang.org/en/4.0/syntax/calling_methods_rdoc.html#label-Block+Argument)
> Doc : [Array#<<](https://docs.ruby-lang.org/en/4.0/Array.html#method-i-3C-3C)
