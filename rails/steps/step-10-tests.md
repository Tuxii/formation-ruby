# Step 10 - Les tests

> **Départ** : la fin du step 09 (ou `origin/step-09`) · **Fichiers fournis** : au 10.2 · **Solution** : `origin/step-10`

## Objectifs

- Lancer les tests et lire un échec
- Écrire des tests de modèle avec des fixtures
- Écrire un test d'intégration qui envoie une requête à l'application

## 10.1 Ce qui existe déjà

Minitest est fourni avec Rails. Lancez les tests écrits par les générateurs :

```bash
bin/rails test
```

Ouvrez `test/controllers/workshops_controller_test.rb`, écrit par le scaffold au step 04 :

- `test "should get index" do ... end` définit un test
- `get workshops_url` envoie une requête à l'application, sans navigateur
- `assert_response`, `assert_difference`, `assert_redirected_to` vérifient le résultat
- `workshops(:one)` lit un atelier dans `test/fixtures/workshops.yml`

Les **fixtures** sont les données de test, en YAML. Elles sont chargées dans une base à part, et chaque test est annulé à la fin : les tests ne se gênent pas entre eux.

> Doc : [Testing Rails Applications](https://guides.rubyonrails.org/testing.html)

## 10.2 Les fixtures

Copiez les fixtures fournies :

```bash
cp -r ../rails/fournis/step-10/. .
```

Lisez-les : une session de 3 places (`ceramics_saturday`), où Alice est déjà inscrite, et trois participants, `alice`, `bruno` et `chloe`. Une fixture en désigne une autre par son nom : dans `sessions.yml`, `workshop: ceramics`.

`workshops(:one)` n'existe plus : dans `workshops_controller_test.rb`, remplacez-le par `workshops(:ceramics)`, puis relancez `bin/rails test`.

> Doc : [Fixtures](https://guides.rubyonrails.org/testing.html#fixtures)

## 10.3 Un test de modèle, et un échec

Un test de modèle ressemble à ceci :

```ruby
require "test_helper"

class BookTest < ActiveSupport::TestCase
  test "un livre sans titre est invalide" do
    book = Book.new(title: "")

    assert_not book.valid?
  end
end
```

**À vous.** Dans `test/models/workshop_test.rb` (le fichier existe depuis le step 01), écrivez un test « la durée s'affiche en heures et minutes » : 90 minutes donnent `"1 h 30"`, 45 donnent `"45 min"`. Comparez avec `assert_equal attendu, obtenu`.

```bash
bin/rails test test/models/workshop_test.rb
```

Cassez ensuite `formatted_duration` exprès (retirez le `rjust`, ajoutez un cas à 65 minutes), relancez, et lisez le message : la valeur attendue, la valeur obtenue, la ligne du test. Réparez.

> Doc : [Testing Models](https://guides.rubyonrails.org/testing.html#testing-models)
> Doc : [Minitest assertions](https://docs.seattlerb.org/minitest/Minitest/Assertions.html)

## 10.4 Les règles des inscriptions

**À vous.** Créez `test/models/registration_test.rb` et écrivez trois tests, avec les fixtures :

1. une inscription de Bruno sur `sessions(:ceramics_saturday)` est valide (`assert registration.valid?`)
2. Alice, déjà inscrite, ne peut pas s'inscrire une seconde fois : l'inscription est invalide, et `registration.errors[:participant_id]` contient `"est déjà inscrit à cette session"` (`assert_includes`)
3. une session pleine refuse une inscription : inscrivez Bruno et Chloé (`session.registrations.create!(participant: ...)`), créez une quatrième personne dans le test (`Participant.create!(name: "Denise", email: "denise@example.test")`), et vérifiez que son inscription a l'erreur `"est complète"` sur `:session`

```bash
bin/rails test test/models/registration_test.rb
```

## 10.5 Un test d'intégration

Un test d'intégration envoie de vraies requêtes à l'application, comme un formulaire :

```ruby
class BooksControllerTest < ActionDispatch::IntegrationTest
  test "créer un livre" do
    assert_difference("Book.count") do
      post books_url, params: { book: { title: "Germinal" } }
    end

    assert_redirected_to book_url(Book.last)
  end
end
```

**À vous.** Créez `test/controllers/registrations_controller_test.rb` avec un test « s'inscrire à une session » : un `post` vers `session_registrations_url(session)`, avec un nom et un email sous la clé `participant`, crée une inscription et redirige vers la session.

Pour finir, toute la suite doit passer :

```bash
bin/rails test
```

> Doc : [Integration Testing](https://guides.rubyonrails.org/testing.html#integration-testing)
