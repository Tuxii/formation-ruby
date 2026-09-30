# Step 07 - La jauge

> **Départ** : la fin du step 06 (ou `origin/step-06`) · **Fichiers fournis** : aucun · **Solution** : `origin/step-07`

## Objectifs

- Ajouter une méthode métier à un modèle et l'afficher
- Écrire une validation personnalisée
- Supprimer une ressource avec un bouton, et confirmer avant

## 7.1 Les places restantes

**À vous.** Dans `Session`, écrivez une méthode `remaining_seats` : la capacité moins le nombre d'inscriptions (`registrations.count`). Vérifiez en console sur `Session.first`.

Affichez-la sur la page d'une session, dans la liste `<dl>`, sous la capacité :

```erb
<dt class="col-sm-3">Places restantes</dt>
<dd class="col-sm-9"><%= @session.remaining_seats %></dd>
```

Ouvrez la session de céramique du 10 octobre : il reste une place. Inscrivez trois personnes, l'une après l'autre. Combien de places restantes ?

## 7.2 Une validation personnalisée

Aucune option de `validates` ne sait compter les inscriptions d'une session. On écrit la règle dans une méthode, déclarée avec `validate` (sans `s`). Dans `Registration` :

```ruby
validate :session_has_seats, on: :create

private
  def session_has_seats
    if session && session.remaining_seats <= 0
      errors.add(:session, "est complète")
    end
  end
```

- `errors.add` ajoute une erreur sur un attribut : `valid?` et `save` renvoient alors `false`
- `on: :create` : la règle ne s'applique qu'à une nouvelle inscription. Une inscription existante n'a pas à être refusée quand la session est pleine.

Essayez de vous inscrire sur la session pleine : l'inscription est refusée avec le message « Session est complète ». Sur la page, remplacez le formulaire par un message quand il n'y a plus de place :

```erb
<% if @session.remaining_seats.positive? %>
  <%= render "registrations/form", session: @session %>
<% else %>
  <p class="text-muted">Plus aucune place disponible.</p>
<% end %>
```

> Doc : [Custom Methods](https://guides.rubyonrails.org/active_record_validations.html#custom-methods)
> Doc : [errors.add](https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-add)

## 7.3 Se désinscrire

Les inscrits en trop du 7.1 doivent pouvoir partir. Ajoutez la route de suppression d'une inscription, à part, comme pour les sessions :

```ruby
resources :registrations, only: :destroy
```

Dans `RegistrationsController`, `set_session` ne sert plus qu'à `create` : `before_action :set_session, only: :create`.

**À vous.** Écrivez l'action `destroy`, comme celle de `SessionsController` au step 05 :

- elle charge l'inscription par son id (`params.expect(:id)`) et la supprime avec `destroy!`
- elle redirige vers la session de l'inscription (`registration.session`), avec le message « Inscription de (nom du participant) annulée. » et `status: :see_other`

Dans `app/views/registrations/_registration.html.erb`, ajoutez une cellule avec un bouton (et, dans l'en-tête du tableau des inscrits de `sessions/show.html.erb`, une colonne vide `<th></th>`) :

```erb
<td class="text-end">
  <%= button_to "Désinscrire", registration, method: :delete, class: "btn btn-sm btn-outline-danger",
        form: { data: { turbo_confirm: "Désinscrire #{registration.participant.name} ?" } } %>
</td>
```

Désinscrivez les personnes en trop, jusqu'à zéro place restante.

- `button_to` produit un petit formulaire, pas un lien : une action qui modifie des données ne doit pas pouvoir partir d'un simple clic sur un lien, d'un préchargement ou d'un robot
- `method: :delete` : le navigateur n'envoie que du `GET` et du `POST`, Rails ajoute un champ caché `_method` que le routeur lit
- `turbo_confirm` : Turbo, installé par défaut avec Rails, demande confirmation avant d'envoyer le formulaire
- `status: :see_other` (303) : après une suppression, le navigateur suit la redirection en `GET`. C'est ce que font déjà `update` et `destroy` dans vos deux contrôleurs.

> Doc : [button_to](https://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-button_to)
> Doc : [Turbo - Requiring Confirmation](https://turbo.hotwired.dev/handbook/drive#requiring-confirmation-for-a-visit)
