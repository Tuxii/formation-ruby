# Step 15 - Stimulus : un peu de JavaScript, accroché au HTML

> **Départ** : la fin du step 14 (ou `origin/step-14`) · **Fichiers fournis** : aucun · **Solution** : `origin/step-15`

## Objectifs

- Savoir ce qu'est un contrôleur Stimulus et comment il est branché sur une page
- Réagir à un évènement du navigateur avec `data-action`
- Lire et modifier des éléments de la page avec les targets

## 15.1 Ce qui est déjà là

Turbo met les pages à jour sans que vous écriviez de JavaScript. Pour les petits comportements qui se passent entièrement dans le navigateur (envoyer un formulaire dès qu'un champ change, compter des caractères, afficher ou masquer un bloc), Rails fournit **Stimulus**. Turbo et Stimulus forment ensemble **Hotwire**.

Ouvrez `app/javascript/controllers/hello_controller.js`, créé avec l'application :

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.textContent = "Hello World!"
  }
}
```

Branchez-le : ajoutez `<p data-controller="hello"></p>` dans `app/views/pages/home.html.erb`, puis rechargez la page d'accueil. Le paragraphe affiche « Hello World! ».

- le fichier `hello_controller.js` donne le nom `hello`, utilisé dans `data-controller="hello"`
- `connect()` s'exécute quand l'élément apparaît dans la page, y compris après une navigation Turbo
- `this.element` est l'élément qui porte `data-controller`
- tout contrôleur placé dans `app/javascript/controllers/` est chargé automatiquement (`config/importmap.rb` et `app/javascript/controllers/index.js`)

Retirez le paragraphe.

> Doc : [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)

## 15.2 Des filtres qui s'appliquent tout seuls

Sur la liste des sessions, il faut cliquer sur « Filtrer » après chaque choix. On veut que la liste se mette à jour dès qu'un filtre change.

Générez un contrôleur :

```bash
bin/rails generate stimulus autosubmit
```

Dans `app/javascript/controllers/autosubmit_controller.js`, remplacez `connect()` par une méthode qui envoie le formulaire :

```js
submit() {
  this.element.requestSubmit()
}
```

Dans `app/views/sessions/_filters.html.erb`, branchez le contrôleur sur le formulaire, et appelez `submit` à chaque changement d'un champ :

```erb
<%= form_with url: sessions_path, method: :get, class: "row g-2 align-items-end mb-4",
      data: { controller: "autosubmit", action: "change->autosubmit#submit" } do |form| %>
```

Retirez le bouton « Filtrer », devenu inutile. Choisissez un statut, cochez « À venir » : la liste et l'URL changent à chaque clic.

- `data-action` se lit « évènement -> contrôleur # méthode » : sur `change`, appeler `submit` du contrôleur `autosubmit`
- l'évènement `change` d'un champ remonte jusqu'au formulaire : une seule action suffit pour tous les champs
- `requestSubmit()` envoie le formulaire comme un clic sur son bouton : Turbo Drive s'en charge, la page n'est pas rechargée

> Doc : [Actions](https://stimulus.hotwired.dev/reference/actions)

## 15.3 À vous : un compteur de caractères

Sous le champ d'une note, on veut afficher le nombre de caractères tapés, « 12 / 200 », mis à jour à chaque frappe.

Pour lire ou modifier un élément précis, un contrôleur déclare des **targets**. Par exemple, un message de bienvenue qui suit ce qu'on tape :

```js
// app/javascript/controllers/greeting_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "name", "output" ]

  greet() {
    this.outputTarget.textContent = `Bonjour, ${this.nameTarget.value} !`
  }
}
```

```erb
<div data-controller="greeting">
  <input data-greeting-target="name" data-action="input->greeting#greet">
  <span data-greeting-target="output"></span>
</div>
```

`static targets = [ "name" ]` donne `this.nameTarget`, l'élément marqué `data-greeting-target="name"`. Dans une vue Rails, `data: { greeting_target: "name" }` produit cet attribut.

**À vous.** Générez un contrôleur `counter`, et branchez-le sur le formulaire de `app/views/notes/_notes.html.erb` :

- deux targets : `input` (le champ de la note) et `count` (un `<small>` à ajouter sous le champ)
- une méthode `update` qui écrit dans `count` la longueur du texte et la longueur maximale : `` `${this.inputTarget.value.length} / ${this.inputTarget.maxLength}` ``
- le champ reçoit `maxlength: 200`, sa target et l'action `input->counter#update`
- `connect()` appelle aussi `update`, pour que le compteur s'affiche dès le chargement

Tapez une note : le compteur suit chaque frappe. Ajoutez-la : après le rechargement, le compteur repart à « 0 / 200 », parce que `connect()` s'exécute à nouveau.

> Doc : [Targets](https://stimulus.hotwired.dev/reference/targets)
> Doc : [Lifecycle Callbacks](https://stimulus.hotwired.dev/reference/lifecycle-callbacks)
