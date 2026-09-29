# Exercice 6 - Métaprogrammation

Écrivez dans `06_metaprogrammation.rb`, lancez avec `ruby 06_metaprogrammation.rb`. Support : `1-ruby.pdf`, section 6.

Le squelette contient une classe `Session` : un titre, une capacité, un statut, et deux sessions pour les essais.

## 6.1 Fabriquer des méthodes : `define_method`

Une session a un statut parmi `STATUSES`. On veut pouvoir demander `session.draft?`, `session.published?` et `session.cancelled?`.

1. Écrivez d'abord les trois méthodes à la main, dans la classe. Que remarquez-vous ?
2. Remplacez-les par une boucle sur `STATUSES`. `define_method` crée une méthode dont le nom est calculé :

```ruby
define_method("#{status}?") do
  # le corps de la méthode
end
```

Vérifiez :

```ruby
p ceramics.published?                    # => true
p bread.draft?                           # => true
p Session.instance_methods(false).sort
```

Ajoutez `:full` à `STATUSES` : quelle méthode apparaît, sans rien écrire d'autre ?

En Rails, `enum :status, [:draft, :published]` fabrique ces méthodes de la même façon.

> Doc : [Module#define_method](https://docs.ruby-lang.org/en/4.0/Module.html#method-i-define_method)

## 6.2 Appeler une méthode par son nom : `send`

`send` appelle une méthode dont le nom est dans une variable :

```ruby
wanted = :published
p ceramics.send("#{wanted}?")            # => true
```

Écrivez `sessions_with_status(sessions, status)`, qui garde les sessions dans ce statut :

```ruby
p sessions_with_status([ceramics, bread], :draft).map(&:title)   # => ["Pain au levain"]
```

> Doc : [Object#send](https://docs.ruby-lang.org/en/4.0/Object.html#method-i-send)

## 6.3 Répondre à des méthodes qui n'existent pas : `method_missing`

Quand un objet reçoit une méthode qu'il ne connaît pas, Ruby appelle sa méthode `method_missing(name, *args)`. Par défaut, elle lève une `NoMethodError`.

Écrivez une classe `Catalog`, construite avec une liste de sessions, qui répond à `find_by_title`, `find_by_capacity`, `find_by_status`... sans définir aucune de ces méthodes. Dans `method_missing` :

- si `name` commence par `find_by_`, retirez ce préfixe (`delete_prefix`) pour obtenir le nom de l'attribut, et renvoyez la première session dont cet attribut vaut `args.first` (pensez à `send`) ;
- sinon, appelez `super`.

```ruby
catalog = Catalog.new([ceramics, bread])
p catalog.find_by_title("Pain au levain").capacity   # => 8
p catalog.find_by_capacity(12).title                 # => "Initiation à la céramique"
p catalog.find_by_status(:cancelled)                 # => nil
catalog.hello                                        # => NoMethodError
```

- Pourquoi `catalog.hello` lève-t-il toujours une erreur ? Que se passe-t-il sans le `super` ?
- Que renvoie `catalog.methods.include?(:find_by_title)` ?

En Rails, `Workshop.find_by_title("...")` fonctionne ainsi : aucune méthode `find_by_title` n'est écrite nulle part.

**`respond_to?` (bonus).** `catalog.respond_to?(:find_by_title)` renvoie `false`. Définissez `respond_to_missing?(name, include_private = false)` pour qu'il renvoie `true`.

> Doc : [BasicObject#method_missing](https://docs.ruby-lang.org/en/4.0/BasicObject.html#method-i-method_missing)
> Doc : [Object#respond_to_missing?](https://docs.ruby-lang.org/en/4.0/Object.html#method-i-respond_to_missing-3F)

## 6.4 D'où vient cette méthode ?

```ruby
p ceramics.method(:published?).owner
p ceramics.method(:title).owner
p ceramics.method(:frozen?).owner
p Session.ancestors
```

Qui a défini chacune de ces méthodes ? Dans IRB, `show_source Session#published?` affiche son code.

> Doc : [Method#owner](https://docs.ruby-lang.org/en/4.0/Method.html#method-i-owner)

## 6.5 Classes ouvertes (bonus)

Ajoutez à `String` une méthode `shout` :

```ruby
p "bonjour".shout                        # => "BONJOUR !"
```

Une classe Ruby peut être rouverte n'importe où, même une classe du langage. Rails le fait aussi : `"".blank?` n'existe pas en Ruby pur.
