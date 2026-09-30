# Step 10 - Les tests

> **Départ** : la fin du step 09 (ou `origin/step-09`) · **Fichiers fournis** : au 10.2 · **Solution** : `origin/step-10`

## Objectifs

- Lancer les tests et lire un échec
- Écrire des tests de modèle avec des fixtures
- Écrire un test d'intégration qui envoie une requête à l'application

## 10.1 Ce qui existe déjà

Minitest est fourni avec Rails, sans rien à installer. Lancez les tests écrits par les générateurs :

```bash
bin/rails test
```

Ouvrez `test/controllers/workshops_controller_test.rb`, écrit par le scaffold au step 04 :

- `test "should get index" do ... end` définit un test
- `get workshops_url` envoie une requête à l'application, sans navigateur
- `assert_response`, `assert_difference`, `assert_redirected_to` vérifient le résultat
- `workshops(:one)` lit un atelier dans `test/fixtures/workshops.yml`

Les **fixtures** sont les données de test, écrites en YAML. Elles sont chargées dans une base à part, `storage/test.sqlite3`, et chaque test est annulé à la fin : les tests ne se gênent pas entre eux.

> Doc : [Testing Rails Applications](https://guides.rubyonrails.org/testing.html)

## 10.2 Les fixtures

Copiez les fixtures fournies, qui remplacent `workshops.yml` :

```bash
cp -r ../rails/fournis/step-10/. .
```

Lisez-les. Une fixture en désigne une autre par son nom : dans `sessions.yml`, `workshop: ceramics`. L'ERB calcule des dates relatives : `<%= 1.week.from_now %>`.

`workshops(:one)` n'existe plus : dans `workshops_controller_test.rb`, remplacez-le par `workshops(:ceramics)`, puis relancez `bin/rails test`.

> Doc : [Fixtures](https://guides.rubyonrails.org/testing.html#fixtures)

## 10.3 Un premier test de modèle

Créez `test/models/workshop_test.rb` (remplacez le fichier généré au step 01) :

```ruby
require "test_helper"

class WorkshopTest < ActiveSupport::TestCase
  test "la durée s'affiche en heures et minutes" do
    assert_equal "1 h 30", Workshop.new(duration_minutes: 90).formatted_duration
  end
end
```

```bash
bin/rails test test/models/workshop_test.rb
```

Complétez ce test avec les autres cas du step 02 : 60 minutes donnent `"1 h"`, 45 donnent `"45 min"`, 65 donnent `"1 h 05"`. Ajoutez un test : sans durée, `formatted_duration` renvoie `nil` (`assert_nil`).

Cassez volontairement `formatted_duration` (par exemple, retirez le `rjust`), relancez, lisez le message d'échec : la valeur attendue, la valeur obtenue, la ligne du test. Réparez.

## 10.4 Tester les règles des inscriptions

Créez `test/models/registration_test.rb`. Premier test, avec les fixtures :

```ruby
require "test_helper"

class RegistrationTest < ActiveSupport::TestCase
  test "une inscription sur une session avec des places est valide" do
    registration = Registration.new(session: sessions(:ceramics_saturday), participant: participants(:bruno))

    assert registration.valid?
  end
end
```

`sessions(:ceramics_saturday)` a 3 places, dont une prise par Alice (`registrations(:alice_saturday)`). Écrivez ensuite un test pour chaque règle :

1. un participant ne s'inscrit qu'une fois à une session : Alice, à nouveau, est refusée (`assert_not registration.valid?`, puis `assert_includes registration.errors[:participant_id], "est déjà inscrit à cette session"`)
2. une session pleine refuse une inscription : inscrivez Bruno et Chloé (`session.registrations.create!(participant: ...)`), créez une quatrième personne dans le test (`Participant.create!(name: "Denise", email: "denise@example.test")`), et vérifiez que son inscription a l'erreur `"est complète"` sur `:session`
3. la dernière place passe la session à « complète » : après les inscriptions de Bruno et Chloé, `assert session.reload.full?`
4. une désinscription repasse une session complète à « publiée »

Et dans `test/models/participant_test.rb` : l'email est enregistré en minuscules, sans espaces.

Si vous avez le temps, `test/models/session_test.rb` : `remaining_seats` de `sessions(:ceramics_saturday)`, et le scope `upcoming`, qui contient cette session mais pas `sessions(:bike_past)` (`assert_includes`, `assert_not_includes`).

Au 4, sans `reload`, le test échoue : `registrations(:alice_saturday)` charge sa session dans un autre objet Ruby, et c'est cet objet que le callback modifie, pas votre variable `session`. `reload` relit la ligne en base.

Commentez la ligne `after_destroy` de `Registration`, relancez : quel test échoue ? Décommentez.

```bash
bin/rails test test/models
bin/rails test test/models/registration_test.rb:12    # le test qui commence à la ligne 12
```

> Doc : [Testing Models](https://guides.rubyonrails.org/testing.html#testing-models)
> Doc : [Minitest assertions](https://docs.seattlerb.org/minitest/Minitest/Assertions.html)

## 10.5 Un test d'intégration

Un test d'intégration envoie de vraies requêtes à l'application, comme le formulaire. Créez `test/controllers/registrations_controller_test.rb` :

```ruby
require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "s'inscrire à une session" do
    session = sessions(:ceramics_saturday)

    assert_difference("Registration.count") do
      post session_registrations_url(session), params: { participant: { name: "Denise", email: "denise@example.test" } }
    end

    assert_redirected_to session_url(session)
  end
end
```

Ajoutez :

1. une session pleine refuse l'inscription : passez la capacité à 1 (`session.update!(capacity: 1)`), vérifiez qu'aucune inscription n'est créée (`assert_no_difference`), puis le message : `assert_equal "Inscription impossible : Session est complète.", flash[:alert]`
2. se désinscrire : `delete registration_url(registrations(:alice_saturday))` supprime une inscription

Pour finir, toute la suite doit passer :

```bash
bin/rails test
```

> Doc : [Integration Testing](https://guides.rubyonrails.org/testing.html#integration-testing)
