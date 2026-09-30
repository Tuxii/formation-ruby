# Step 14 - Un support PDF par atelier

> **Départ** : la fin du step 13 (ou `origin/step-13`) · **Fichiers fournis** : au 14.3 · **Solution** : `origin/step-14`

## Objectifs

- Joindre un fichier à un modèle avec Active Storage
- Envoyer le fichier depuis un formulaire, et le proposer au téléchargement
- Savoir où le fichier est stocké

## 14.1 Installer Active Storage

Chaque atelier peut avoir un support de cours en PDF. Active Storage, fourni avec Rails, gère les fichiers joints :

```bash
bin/rails active_storage:install
bin/rails db:migrate
```

Lisez la migration : trois tables, qui servent à tous les fichiers de tous les modèles. Dans `active_storage_attachments`, les colonnes `record_type` et `record_id` : c'est une association polymorphe, comme les notes du step 11.

> Doc : [Active Storage Overview](https://guides.rubyonrails.org/active_storage_overview.html)

## 14.2 Joindre un fichier

Dans `Workshop` :

```ruby
has_one_attached :handout
```

Pas de nouvelle colonne dans `workshops` : le lien passe par les tables d'Active Storage.

Trois modifications pour l'envoyer et le télécharger :

1. dans `WorkshopsController#workshop_params`, ajoutez `:handout` à la liste
2. dans `workshops/_form.html.erb`, avant la case « Publié » :

   ```erb
   <div class="mb-3">
     <%= form.label :handout, class: "form-label" %>
     <%= form.file_field :handout, accept: "application/pdf", class: "form-control" %>
   </div>
   ```

3. dans `workshops/show.html.erb`, dans le frame, entre la description et le lien « Modifier » :

   ```erb
   <% if @workshop.handout.attached? %>
     <p><%= link_to "Télécharger le support PDF", rails_blob_path(@workshop.handout, disposition: "attachment"), class: "btn btn-outline-primary btn-sm" %></p>
   <% end %>
   ```

Modifiez un atelier, joignez-lui un PDF de votre ordinateur, puis téléchargez-le depuis sa page.

> Doc : [has_one_attached](https://guides.rubyonrails.org/active_storage_overview.html#attaching-files-to-records-has-one-attached)

## 14.3 Où est le fichier ?

Les seeds fournis joignent un support à l'atelier de céramique :

```bash
cp -r ../rails/fournis/step-14/. .
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

## 14.4 N'accepter que des PDF

`accept: "application/pdf"` filtre l'affichage dans la fenêtre de sélection du navigateur, il ne vérifie rien côté serveur.

**À vous.** Écrivez dans `Workshop` une validation personnalisée `handout_is_a_pdf`, comme celle du 7.2 : quand un fichier est joint (`handout.attached?`) et que son `content_type` n'est pas `"application/pdf"`, elle ajoute sur `:handout` l'erreur « n'est pas un fichier PDF ».

Essayez d'envoyer une image : dans la fenêtre de sélection, choisissez l'option qui affiche tous les fichiers. Le formulaire revient avec l'erreur.
