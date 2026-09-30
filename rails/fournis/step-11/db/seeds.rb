# Seeds idempotents : on peut les rejouer autant de fois qu'on veut (bin/rails db:seed)
# sans créer de doublons, grâce à find_or_create_by!.
#
# Les dates sont fixes : fin septembre et octobre 2026.

# --- Ateliers -----------------------------------------------------------------

workshops = [
  { title: "Initiation à la céramique", duration_minutes: 120, published: true,
    description: "Modelage à la main et premier passage au tour. Tout le matériel est fourni." },
  { title: "Réparer son vélo", duration_minutes: 90, published: true,
    description: "Crevaison, freins, dérailleur : les réparations qu'on peut faire soi-même." },
  { title: "Cuisine japonaise : les makis", duration_minutes: 150, published: true,
    description: "Préparer le riz, rouler les makis, découvrir les bases de l'assaisonnement." },
  { title: "Couture : ourlets et boutons", duration_minutes: 60, published: true,
    description: "Les retouches du quotidien, à la main puis à la machine." },
  { title: "Photographier avec son téléphone", duration_minutes: 90, published: false,
    description: "Lumière, cadrage et retouche, sans rien acheter de plus." },
  { title: "Compost et jardinage urbain", duration_minutes: 120, published: false,
    description: "Démarrer un compost sur un balcon et faire pousser des aromatiques." }
]

workshops.each do |attributes|
  Workshop.find_or_create_by!(title: attributes[:title]) do |workshop|
    workshop.assign_attributes(attributes)
  end
end

ceramics = Workshop.find_by!(title: "Initiation à la céramique")
bike     = Workshop.find_by!(title: "Réparer son vélo")
cooking  = Workshop.find_by!(title: "Cuisine japonaise : les makis")
sewing   = Workshop.find_by!(title: "Couture : ourlets et boutons")
photo    = Workshop.find_by!(title: "Photographier avec son téléphone")
# "Compost et jardinage urbain" reste sans session.

# --- Sessions -----------------------------------------------------------------

def session!(workshop, starts_at, capacity:, status: :published)
  Session.find_or_create_by!(workshop: workshop, starts_at: Time.zone.parse(starts_at)) do |session|
    session.capacity = capacity
    session.status = status
  end
end

session!(ceramics, "2026-09-19 10:00", capacity: 8)
session!(ceramics, "2026-10-03 10:00", capacity: 8)
session!(ceramics, "2026-10-10 10:00", capacity: 10)
session!(bike, "2026-10-06 18:30", capacity: 12)
session!(cooking, "2026-09-24 19:00", capacity: 12)
session!(cooking, "2026-10-08 19:00", capacity: 50)
session!(cooking, "2026-10-22 19:00", capacity: 12)
session!(sewing, "2026-10-05 14:00", capacity: 6, status: :cancelled)
session!(sewing, "2026-10-14 14:00", capacity: 6)
session!(photo, "2026-11-04 18:00", capacity: 15, status: :draft)

# Un atelier vélo chaque mardi soir
[ "2026-10-13", "2026-10-20", "2026-10-27", "2026-11-03" ].each do |day|
  session!(bike, "#{day} 18:30", capacity: 12)
end

# --- Participants -------------------------------------------------------------

FIRST_NAMES = %w[Alice Bruno Camille Damien Élodie Fanny Gaëlle Hugo Inès Jules
                 Karim Léa Mathis Nadia Olivier Pauline Quentin Rose Samir Tiphaine]
LAST_NAMES = %w[Martin Bernard Dubois Thomas Robert Richard Petit Durand Leroy Moreau
                Simon Laurent Lefebvre Michel Garcia David Bertrand Roux Vincent Fournier]

participants = (0...60).map do |i|
  first_name = FIRST_NAMES[i % FIRST_NAMES.size]
  last_name = LAST_NAMES[(i * 7 + i / FIRST_NAMES.size) % LAST_NAMES.size]
  email = "#{first_name}.#{last_name}.#{i}".parameterize(separator: ".") + "@example.test"
  Participant.find_or_create_by!(email: email) { |participant| participant.name = "#{first_name} #{last_name}" }
end

# --- Inscriptions --------------------------------------------------------------

def register!(workshop, starts_at, participants)
  session = Session.find_by!(workshop: workshop, starts_at: Time.zone.parse(starts_at))
  participants.each do |participant|
    Registration.find_or_create_by!(session: session, participant: participant)
  end
end

register!(ceramics, "2026-09-19 10:00", participants[0, 6])
register!(ceramics, "2026-10-03 10:00", participants[4, 8])    # complète : 8 inscrits pour 8 places
register!(ceramics, "2026-10-10 10:00", participants[12, 9])   # il reste une place
register!(bike, "2026-10-06 18:30", participants[21, 5])
register!(cooking, "2026-09-24 19:00", participants[30, 10])
register!(cooking, "2026-10-08 19:00", participants[10, 40])   # 40 inscrits
register!(sewing, "2026-10-14 14:00", participants[50, 2])
register!(bike, "2026-10-13 18:30", participants[52, 3])

# --- Notes internes -----------------------------------------------------------

def note!(notable, body)
  notable.notes.find_or_create_by!(body: body)
end

note!(ceramics, "Commander 10 kg d'argile avant la première session.")
note!(cooking, "Vérifier les allergies au moment de l'inscription.")
note!(Session.find_by!(workshop: ceramics, starts_at: Time.zone.parse("2026-10-03 10:00")), "Salle 2, prévoir des tabliers.")
note!(Session.find_by!(workshop: bike, starts_at: Time.zone.parse("2026-10-06 18:30")), "Apporter des chambres à air de rechange.")

puts "#{Workshop.count} ateliers, #{Session.count} sessions, #{Participant.count} participants, " \
     "#{Registration.count} inscriptions, #{Note.count} notes"
