# Exercice 5 - Gestion des erreurs et exceptions

Écrivez dans `05_exceptions.rb`, lancez avec `ruby 05_exceptions.rb`. Support : `1-ruby.pdf`, section 5.

Recopiez d'abord vos modules et vos classes de l'exercice 4 (ou ceux de la correction), sans les données ni les tests. Beaucoup de lignes lèvent une exception, ce qui arrête le script : lisez le message, puis commentez la ligne ou entourez-la d'un `begin` / `rescue`.

Pour les tests, trois participants :

```ruby
alice = Participant.new("Alice Martin", "alice@exemple.fr")
bruno = Participant.new("Bruno Petit", "bruno@exemple.com")
chloe = Participant.new("Chloé Durand", "chloe@exemple.fr")
```

## 5.1 Une capacité qui n'en est pas une

Lancez `Session.new("Initiation à la céramique", "12").remaining_seats`. La création passe ; l'erreur n'arrive que dans `remaining_seats`, et son message parle de `-` et de `String`, pas de capacité.

Faites échouer la création **tout de suite**, avec une `ArgumentError` et un message clair, si la capacité n'est pas un entier strictement positif (`inspect` affiche la valeur reçue avec ses guillemets).

```ruby
Session.new("Initiation à la céramique", "12")   # => ArgumentError: la capacité doit être un entier positif (reçu : "12")
Session.new("Initiation à la céramique", 0)      # => ArgumentError
Session.new("Initiation à la céramique", 12)     # OK
```

Une fois la session créée, `session.capacity = "12"` passe-t-il ?

> Doc : [Kernel#raise](https://docs.ruby-lang.org/en/4.0/Kernel.html#method-i-raise)
> Doc : [ArgumentError](https://docs.ruby-lang.org/en/4.0/ArgumentError.html)

## 5.2 Pourquoi a-t-on refusé ?

`session.register(alice)` renvoie `false`. Complète ? Déjà inscrite ? `false` ne dit rien.

Créez une hiérarchie d'erreurs :

- `RegistrationError`, qui hérite de `StandardError`
- `SessionFullError < RegistrationError`, qui **porte la session** (`attr_reader :session`) et construit son message dans son `initialize` : `"Initiation à la céramique est complète (2 places)"` (`1 place` au singulier)
- `AlreadyRegisteredError < RegistrationError`, qui porte le participant et la session : `"Alice Martin a déjà une inscription à Initiation à la céramique"`

Puis, dans `Session` :

- `register!(participant)` lève l'erreur qui convient (le doublon est vérifié **avant** la jauge), et renvoie l'inscription créée sinon
- `register(participant)` appelle `register!`, renvoie `true`, ou `false` si une `RegistrationError` a été levée

```ruby
session = Session.new("Initiation à la céramique", 2)
p session.register(alice)    # => true
p session.register(alice)    # => false
session.register!(alice)     # => AlreadyRegisteredError: Alice Martin a déjà une inscription à Initiation à la céramique
session.register!(bruno)     # => #<Registration ...>
session.register!(chloe)     # => SessionFullError: Initiation à la céramique est complète (2 places)
session.register!(alice)     # => AlreadyRegisteredError (complète, mais le doublon passe d'abord)
```

Le même couple existe en Rails : `save` renvoie un booléen, `save!` lève une exception.

> Doc : [Custom exceptions](https://docs.ruby-lang.org/en/4.0/language/exceptions_md.html#label-Custom+Exceptions)
> Doc : [Exception.new](https://docs.ruby-lang.org/en/4.0/Exception.html#method-c-new)
> Doc : [Exception#message](https://docs.ruby-lang.org/en/4.0/Exception.html#method-i-message)

## 5.3 Attraper au bon niveau

**a.** Sur une session de 2 places, bouclez sur `[alice, bruno, alice, chloe]` : appelez `register!` et affichez un message selon l'erreur, en utilisant la session ou le participant portés par l'erreur.

```
Alice Martin : inscription confirmée
Bruno Petit : inscription confirmée
Alice Martin : déjà inscrite, rien à faire
Chloé Durand : désolé, Initiation à la céramique est complète
```

**b.** Refaites la boucle avec un seul `rescue RegistrationError => e`, qui affiche `e.message`. Qu'est-ce qu'on gagne ? Qu'est-ce qu'on perd ?

```
Alice Martin : inscription confirmée
Bruno Petit : inscription confirmée
Alice Martin : Alice Martin a déjà une inscription à Initiation à la céramique
Chloé Durand : Initiation à la céramique est complète (2 places)
```

**c.** Un collègue a écrit ceci :

```ruby
begin
  session = Session.new("Aquarelle en plein air", 3)
  session.register!(alice)
  puts "Bienvenue #{alice.nmae}"
rescue => e
  puts "Inscription refusée"
end
p session.count
```

Sans l'exécuter : qu'affiche ce code, et Alice est-elle inscrite ? Vérifiez en le lançant.

> Doc : [Rescue clauses](https://docs.ruby-lang.org/en/4.0/language/exceptions_md.html#label-Rescue+Clauses)
> Doc : [Multiple rescue clauses](https://docs.ruby-lang.org/en/4.0/language/exceptions_md.html#label-Multiple+Rescue+Clauses)
> Doc : [Built-in exception class hierarchy](https://docs.ruby-lang.org/en/4.0/Exception.html#class-Exception-label-Built-In+Exception+Class+Hierarchy)

## 5.4 else et ensure : le journal du guichet

**a. else.** Dans le code du collègue (5.3 c), déplacez le `puts "Bienvenue ..."` dans un `else`, après le `rescue`. Relancez : que se passe-t-il, et pourquoi est-ce mieux ? Corrigez ensuite la faute de frappe pour continuer.

**b. ensure.** Écrivez `register_all(session, participants)`, qui tente d'inscrire chaque participant avec `register!` et renvoie un journal, `{succeeded: [les noms], refused: [les messages d'erreur]}` :

- l'ajout dans `succeeded` se fait dans un `else`
- la méthode affiche « Guichet fermé » dans un `ensure` placé au niveau du `def`

```ruby
session = Session.new("Initiation à la céramique", 2)
p register_all(session, [alice, bruno, alice, chloe])
# => Guichet fermé
# => {succeeded: ["Alice Martin", "Bruno Petit"], refused: ["Alice Martin a déjà une inscription à Initiation à la céramique", "Initiation à la céramique est complète (2 places)"]}
```

Appelez-la avec un participant manquant : `register_all(Session.new("Aquarelle en plein air", 3), [alice, nil])`. L'erreur est-elle attrapée ? « Guichet fermé » s'affiche-t-il ?

> Doc : [Else clause](https://docs.ruby-lang.org/en/4.0/language/exceptions_md.html#label-Else+Clause)
> Doc : [Ensure clause](https://docs.ruby-lang.org/en/4.0/language/exceptions_md.html#label-Ensure+Clause)

## 5.5 Relancer une exception

Le guichet veut garder une trace des erreurs d'inscription, sans décider à la place de l'appelant.

Écrivez `register_with_logging(session, participant, log)`, qui appelle `register!` et, en cas de `RegistrationError`, ajoute `"#{e.class} : #{e.message}"` au tableau `log`, puis **relance** l'exception avec `raise` seul. Pas besoin de `begin` : un `def` peut porter directement son `rescue`.

```ruby
log = []
session = Session.new("Pain au levain", 1)
register_with_logging(session, alice, log)
begin
  register_with_logging(session, bruno, log)
rescue SessionFullError => e
  puts "L'appelant décide : proposer une autre date pour #{e.session.title}"
end
p log
# => L'appelant décide : proposer une autre date pour Pain au levain
# => ["SessionFullError : Pain au levain est complète (1 place)"]
```

Copiez la méthode sous le nom `register_without_raise`, sans le `raise` : que renvoie `register_without_raise(session, chloe, [])`, et qu'en conclurait l'appelant ?

> Doc : [Re-raising an exception](https://docs.ruby-lang.org/en/4.0/language/exceptions_md.html#label-Re-Raising+an+Exception)
> Doc : [Begin-less exception handlers](https://docs.ruby-lang.org/en/4.0/language/exceptions_md.html#label-Begin-Less+Exception+Handlers)
