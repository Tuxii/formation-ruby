# Step 12 - Un support PDF par atelier

> **Départ** : la fin du step 11 (ou `origin/step-11`) · **Fichiers fournis** : au 12.3 · **Solution** : `origin/step-12`

## Objectifs

- Joindre un fichier à un modèle avec Active Storage
- Envoyer le fichier depuis un formulaire, et le proposer au téléchargement
- Savoir où le fichier est stocké

## 12.1 Installer Active Storage

Chaque atelier peut avoir un support de cours en PDF. Active Storage, fourni avec Rails, gère les fichiers joints :

```bash
bin/rails active_storage:install
bin/rails db:migrate
```

Lisez la migration : trois tables, qui servent à tous les fichiers de tous les modèles. Dans `active_storage_attachments`, les colonnes `record_type` et `record_id` : c'est une association polymorphe, comme les notes du step 11.

> Doc : [Active Storage Overview](https://guides.rubyonrails.org/active_storage_overview.html)

## 12.2 Joindre un fichier

Pour une couverture de livre, il faut quatre choses :

```ruby
# le modèle
class Book < ApplicationRecord
  has_one_attached :cover
end

# le contrôleur : le champ est autorisé
params.expect(book: [ :title, :cover ])
```

```erb
<%# le formulaire %>
<%= form.file_field :cover, accept: "image/png,image/jpeg" %>

<%# la page du livre : un lien de téléchargement, s'il y a un fichier %>
<% if @book.cover.attached? %>
  <%= link_to "Télécharger", rails_blob_path(@book.cover, disposition: "attachment") %>
<% end %>
```

Pas de nouvelle colonne dans `books` : le lien passe par les tables d'Active Storage.

**À vous.** Faites la même chose pour le support d'un atelier, que l'on appellera `handout` :

- dans `Workshop`, le `has_one_attached`
- dans `WorkshopsController#workshop_params`, le champ autorisé
- dans `workshops/_form.html.erb`, avant la case « Publié », un champ qui n'accepte que les PDF (`accept: "application/pdf"`), avec son label, dans un `<div class="mb-3">` comme les autres champs
- dans `workshops/show.html.erb`, sous la description, le lien « Télécharger le support PDF » quand un fichier est joint

Modifiez un atelier, joignez-lui un PDF de votre ordinateur, puis téléchargez-le depuis sa page.

> Doc : [has_one_attached](https://guides.rubyonrails.org/active_storage_overview.html#attaching-files-to-records-has-one-attached)
> Doc : [Serving Files](https://guides.rubyonrails.org/active_storage_overview.html#serving-files)

## 12.3 Où est le fichier ?

Les seeds fournis joignent un support à l'atelier de céramique :

```bash
cp -r ../rails/fournis/step-12/. .
bin/rails db:seed
```

Ouvrez `config/storage.yml` et le dossier `storage/` : en développement, les fichiers sont écrits sur le disque, dans des sous-dossiers aux noms aléatoires. La base ne garde que les informations sur le fichier (nom, type, taille) :

```ruby
workshop = Workshop.joins(:handout_attachment).first
workshop.handout.filename.to_s
workshop.handout.content_type
workshop.handout.byte_size
```

En production, on change de service dans `config/storage.yml` (Amazon S3, Google Cloud Storage, un disque partagé...) sans toucher au code de l'application.

## 12.4 N'accepter que des PDF

`accept: "application/pdf"` filtre l'affichage dans la fenêtre de sélection du navigateur, il ne vérifie rien côté serveur.

**À vous.** Écrivez dans `Workshop` une validation personnalisée `handout_is_a_pdf`, comme celle du 7.2 : quand un fichier est joint (`handout.attached?`) et que son `content_type` n'est pas `"application/pdf"`, elle ajoute sur `:handout` l'erreur « n'est pas un fichier PDF ».

Essayez d'envoyer une image : dans la fenêtre de sélection, choisissez l'option qui affiche tous les fichiers. Le formulaire revient avec l'erreur.
