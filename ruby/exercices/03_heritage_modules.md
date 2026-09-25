# Exercice 3 - Héritage et modules

Écrivez dans `03_heritage_modules.rb`, lancez avec `ruby 03_heritage_modules.rb`. Support : `1-ruby.pdf`, section 3.

Recopiez d'abord vos classes `Session` et `Workshop` de l'exercice 2 (ou celles de la correction) à l'endroit prévu. Les modules se placent au-dessus : une classe ne peut inclure qu'un module déjà défini. Une ligne qui lève une erreur arrête le script : lisez le message, puis commentez la ligne.

En tête de la partie Tests, créez un atelier et une session :

```ruby
ceramics = Workshop.new("Initiation à la céramique", duration_minutes: 90,
                        description: "Modeler, tourner, émailler, et repartir avec son bol.")
saturday = ceramics.schedule(capacity: 6, starts_at: Time.new(2026, 10, 10, 9, 30))
```

## 3.1 Héritage - OnlineSession

Certains ateliers se font aussi en visio. Créez une classe `OnlineSession` qui hérite de `Session` :

- un `initialize(title, capacity, video_link)`
- `video_link` en lecture seule
- `full?` renvoie toujours `false`
- `to_s` ajoute le lien au texte de `Session#to_s`, sans le recopier (`super` marche dans toute méthode redéfinie)

Dans `initialize`, commencez par écrire `super` tout seul, sans parenthèses. Lisez l'erreur. Que fait `super` sans argument ? Et `super()` ?

```ruby
colors = OnlineSession.new("Théorie des couleurs", 2, "https://visio.exemple.fr/couleurs")
puts colors                     # => Théorie des couleurs [draft] 2/2 places libres - en ligne : https://visio.exemple.fr/couleurs
colors.publish
puts colors.register("Alice")   # => true
puts colors.register("Bruno")   # => true
puts colors.register("Chloé")   # => true (jamais complète)
puts colors
```

Qu'est-ce qui cloche dans le dernier affichage ? Quelle méthode aurait-il été plus juste de redéfinir ?

> Doc : [Inheritance](https://docs.ruby-lang.org/en/4.0/syntax/modules_and_classes_rdoc.html#label-Inheritance)

## 3.2 Module Publishable

`Workshop` sait se publier. On veut que `Session` le sache aussi, sans copier-coller, et sans héritage : un atelier n'est pas une sorte de session.

Créez un module `Publishable` avec `publish` (passe `@published` à `true`), `unpublish` (à `false`) et `published?`.

Retirez de `Workshop` ses méthodes `publish` et `published?` ainsi que `@published = false`, et incluez-y le module. Testez sur un atelier neuf :

```ruby
p Workshop.new("Pain au levain", duration_minutes: 120).published?   # ?
```

Que vaut une variable d'instance jamais affectée ? Corrigez `published?` dans le module pour qu'elle renvoie toujours `true` ou `false` (ici `false`).

Incluez maintenant `Publishable` dans `Session` et retirez-en `published?`. Gardez le `publish` de `Session`, qui change le statut : `Session` a donc sa propre méthode `publish`, et le module en apporte une autre. **Avant de lancer**, prédisez :

```ruby
saturday.publish
p saturday.status        # ?
p saturday.published?    # ?
```

Vérifiez, puis demandez à Ruby d'où viennent les méthodes :

```ruby
p Session.ancestors
p saturday.method(:publish).owner
p saturday.method(:published?).owner
```

Faites en sorte que `Session#publish` change le statut **et** exécute le `publish` du module (un seul mot à ajouter). Vérifiez que `p saturday.published?` affiche maintenant `true`. `p saturday.method(:publish).super_method` montre la méthode que ce mot appelle.

> Doc : [Method lookup](https://docs.ruby-lang.org/en/4.0/syntax/calling_methods_rdoc.html#label-Method+Lookup)
> Doc : [Method#owner](https://docs.ruby-lang.org/en/4.0/Method.html#method-i-owner)
> Doc : [Method#super_method](https://docs.ruby-lang.org/en/4.0/Method.html#method-i-super_method)

## 3.3 Module Describable

Pour le catalogue papier, on veut une fiche texte, pour les ateliers comme pour les sessions :

```
Initiation à la céramique
-------------------------
Modeler, tourner, émailler, et repartir avec son bol.
```

Créez un module `Describable` avec une méthode `summary` qui construit ce texte à partir de `title` et de `description` (heredoc `<<~TEXT` ; `"-" * 5` donne `"-----"`).

Incluez-le dans `Workshop` et dans `Session`, puis appelez `saturday.summary`. Lisez l'erreur. Le module appelle deux méthodes qu'il ne définit pas : où est écrit que `Session` doit les fournir ?

Ajoutez à `Session` une méthode `description` qui renvoie celle de son atelier (ou `""` sans atelier).

```ruby
puts ceramics.summary
puts saturday.summary     # la même fiche
```

> Doc : [Here document literals](https://docs.ruby-lang.org/en/4.0/syntax/literals_rdoc.html#label-Here+Document+Literals)
> Doc : [String#*](https://docs.ruby-lang.org/en/4.0/String.html#method-i-2A)

## 3.4 extend - Numberable

Chaque session doit recevoir un numéro unique à sa création : 1, 2, 3... Ce compteur n'appartient à aucune session : il appartient à la classe.

Créez un module `Numberable` avec une méthode `next_number` qui incrémente un compteur et renvoie la nouvelle valeur. Ajoutez-le à `Session` avec `extend` (et non `include`), puis affectez `@number = self.class.next_number` dans `Session#initialize` et ajoutez `number` en lecture seule.

```ruby
p Session.respond_to?(:next_number)    # => true
p saturday.respond_to?(:next_number)   # => false
a = Session.new("Croquis express", 8)
b = Session.new("Croquis express", 8)
p b.number - a.number                  # => 1
p saturday.number                      # => 1
p colors.number                        # => 1
```

Dans `next_number`, qui est `self` ? Pourquoi `colors` a-t-elle le même numéro que `saturday` ?

> Doc : [Object#extend](https://docs.ruby-lang.org/en/4.0/Object.html#method-i-extend)
> Doc : [self](https://docs.ruby-lang.org/en/4.0/syntax/modules_and_classes_rdoc.html#label-self)

## 3.5 Chaîne d'héritage et duck typing

```ruby
p OnlineSession.ancestors
p colors.is_a?(Session)
p colors.is_a?(Publishable)
p colors.instance_of?(Session)
```

Où apparaissent les modules dans la liste, et dans quel ordre ?

Écrivez une méthode `print_catalog(items)` qui affiche la fiche de chaque élément qui sait en produire une, et ignore les autres en le signalant (avec `inspect`, d'où les guillemets autour de la chaîne). Elle ne doit tester **aucune classe** :

```ruby
print_catalog([ceramics, saturday, "une chaîne", 42])
# => les deux fiches, puis :
# => (ignoré : "une chaîne" n'a pas de fiche)
# => (ignoré : 42 n'a pas de fiche)
```

> Doc : [Module#ancestors](https://docs.ruby-lang.org/en/4.0/Module.html#method-i-ancestors)
> Doc : [Object#is_a?](https://docs.ruby-lang.org/en/4.0/Object.html#method-i-is_a-3F)
> Doc : [Object#respond_to?](https://docs.ruby-lang.org/en/4.0/Object.html#method-i-respond_to-3F)
