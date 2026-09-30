# Step 08 - Les callbacks

> **Départ** : la fin du step 07 (ou `origin/step-07`) · **Fichiers fournis** : aucun · **Solution** : `origin/step-08`

## Objectifs

- Exécuter du code à un moment précis de la vie d'un modèle : avant la validation, après une création, après une suppression
- Connaître le raccourci `normalizes`
- Savoir ce qu'un callback cache à qui lit le contrôleur

## 8.1 Deux fois la même personne

Sur une session qui a des places, inscrivez « Alice Martin » avec `alice@example.test`, puis sur une autre session, la même personne avec `Alice@Example.test`. En console :

```ruby
Participant.where("email LIKE ?", "%alice@example%").pluck(:email)
```

`pluck` renvoie directement les valeurs d'une colonne, sans créer d'objets. Deux participants pour une seule personne : l'email n'est pas le même, caractère par caractère.

Un **callback** est une méthode qu'Active Record appelle à un moment précis : avant la validation, avant ou après l'enregistrement, après la suppression... Dans `Participant` :

```ruby
before_validation :normalize_email

private
  def normalize_email
    self.email = email.strip.downcase if email
  end
```

`self.email =` appelle le setter de l'attribut. Sans `self`, Ruby créerait une variable locale `email` (exercice Ruby 2.4).

Supprimez le doublon en console (`Participant.find_by(email: "Alice@Example.test").destroy`), puis réinscrivez `Alice@Example.test` sur la seconde session. Que dit le message ?

> Doc : [Active Record Callbacks](https://guides.rubyonrails.org/active_record_callbacks.html)

## 8.2 Le raccourci : `normalizes`

Le callback normalise l'email à l'enregistrement, mais pas la **recherche**. Dans le contrôleur, `find_or_initialize_by(email: "Alice@Example.test")` ne trouve pas `alice@example.test` : il prépare une nouvelle participante, que le callback normalise, et que la validation d'unicité refuse.

Rails a un raccourci qui normalise l'attribut à l'affectation **et** dans les recherches. Remplacez le callback et sa méthode par :

```ruby
normalizes :email, with: ->(email) { email.strip.downcase }
```

Réessayez : Alice est retrouvée et inscrite à la seconde session. En console, la valeur cherchée est normalisée avant de partir dans le SQL :

```ruby
Participant.where(email: " ALICE@example.test").to_sql
```

> Doc : [normalizes (API)](https://api.rubyonrails.org/classes/ActiveModel/Attributes/Normalization/ClassMethods.html#method-i-normalizes)

## 8.3 « Complète », automatiquement

Le statut `full` existe depuis le step 05, mais personne ne le pose. On veut qu'une session publiée passe à « Complète » quand la dernière place est prise, et redevienne « Publiée » quand une place se libère.

**À vous.** Deux choses à écrire :

1. Dans `Session`, une méthode `refresh_status` qui recalcule le statut, avec les méthodes de l'`enum` (5.3) et `remaining_seats` :
   - une session publiée qui n'a plus de place passe à complète (`full!`)
   - une session complète qui a de nouveau une place redevient publiée (`published!`)
   - dans les autres cas, rien ne change

   Essayez-la en console sur la session de céramique du 3 octobre, 8 inscrits pour 8 places : `Session.find_by(capacity: 8, starts_at: "2026-10-03".."2026-10-04").refresh_status`.
2. Dans `Registration`, deux callbacks, `after_create` et `after_destroy`, déclarés comme le `before_validation` du 8.1 : ils appellent une méthode privée `refresh_session_status`, qui appelle `session.refresh_status`.

Sur la page d'une session publiée qui a des places, inscrivez des personnes jusqu'à la dernière place : le badge passe à « Complète ». Désinscrivez quelqu'un : il repasse à « Publiée ».

Rejouez les seeds depuis une base vide :

```bash
bin/rails db:reset
```

Les seeds créent les inscriptions : les callbacks s'exécutent aussi pour eux. La session de céramique du 3 octobre, 8 inscrits pour 8 places, est maintenant « Complète ». Relancez `bin/dev` : sinon, le serveur continue de lire l'ancienne base.

## 8.4 Ce que le callback cache

Relisez `RegistrationsController#destroy` : rien n'y dit que la session peut changer de statut. C'est le prix d'un callback : l'effet est déclaré dans le modèle, loin de l'appel qui le déclenche.

- `normalize_email` ne touchait que l'objet en cours d'enregistrement : c'est l'usage le plus sûr
- `refresh_session_status` modifie **un autre objet** : pratique, mais invisible pour qui lit le contrôleur

Devant un modèle que vous n'avez pas écrit, cherchez les callbacks en premier : `before_`, `after_`, et les `dependent:` des associations, qui en sont aussi.

> Doc : [Available Callbacks](https://guides.rubyonrails.org/active_record_callbacks.html#available-callbacks)
