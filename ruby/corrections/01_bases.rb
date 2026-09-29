# ============================================
# Correction 1 - Les bases de Ruby
# ============================================
# Les lignes qui lèvent une erreur volontairement sont entourées de begin / rescue
# (exercice 5) pour que le script aille jusqu'au bout.

# --- 1.1 Combien reste-t-il de places ? ---

session = {
  title: "Initiation à la céramique",
  capacity: 12,
  registrants: ["Alice", "Bruno", "Chloé"],
  status: :published
}

# Pas de return : une méthode Ruby renvoie la valeur de sa dernière expression
def remaining_seats(session)
  session[:capacity] - session[:registrants].size
end

puts remaining_seats(session)   # => 9

new_session = { title: "Pain au levain", capacity: 8, status: :draft }

begin
  remaining_seats(new_session)
rescue NoMethodError => e
  puts "#{e.class}: #{e.message}"
end
# => NoMethodError: undefined method 'size' for nil
# session[:registrants] vaut nil, et nil n'a pas de méthode size

# --- 1.2 Types et symboles ---

status = :published
instructor = nil

puts "#{status} est un #{status.class}"           # => published est un Symbol
puts "#{instructor} est un #{instructor.class}"   # =>  est un NilClass

# L'interpolation appelle to_s sur chaque valeur :
p :published.to_s   # => "published"
p nil.to_s          # => ""

p true.class        # => TrueClass
p false.class       # => FalseClass (pas de classe Boolean)

# --- 1.3 Chaînes de caractères ---

title = "Initiation à la céramique"
p title.length   # => 25
p title.upcase   # => "INITIATION À LA CÉRAMIQUE"

# Le piège du !
title = "Initiation à la céramique"
label = title
p title.upcase!   # => "INITIATION À LA CÉRAMIQUE"
p label           # => "INITIATION À LA CÉRAMIQUE"
p title.upcase!   # => nil (rien n'a changé, donc nil)

# label = title copie la référence : les deux variables désignent le même objet,
# et upcase! modifie cet objet en place.

begin
  title.upcase!.length
rescue NoMethodError => e
  puts "#{e.class}: #{e.message}"
end
# => NoMethodError: undefined method 'length' for nil

# --- 1.4 Hash : lire sans se faire piéger ---

p session[:instructor]   # => nil (clé absente, aucune erreur)

begin
  session.fetch(:instructor)
rescue KeyError => e
  puts "#{e.class}: #{e.message}"
end
# => KeyError: key not found: :instructor

p session.fetch(:instructor, "à définir")   # => "à définir"

p session["title"]   # => nil (la clé est le symbole :title, pas la chaîne "title")

p session[:instructor]&.upcase   # => nil (upcase n'est pas appelé sur nil)
p session[:title]&.upcase        # => "INITIATION À LA CÉRAMIQUE"

# Cette définition remplace celle du 1.1
def remaining_seats(session)
  session[:capacity] - session.fetch(:registrants, []).size
end

puts remaining_seats(session)       # => 9
puts remaining_seats(new_session)   # => 8

# --- 1.5 Une méthode de formatage ---

def format_session(session, with_seats: true)
  text = "#{session[:title]} [#{session[:status].to_s.upcase}]"
  return text unless with_seats

  seats = remaining_seats(session)
  label = seats == 1 ? "place restante" : "places restantes"
  "#{text} #{seats} #{label}"
end

puts format_session(session)
# => Initiation à la céramique [PUBLISHED] 9 places restantes

puts format_session(session, with_seats: false)
# => Initiation à la céramique [PUBLISHED]

begin
  format_session(session, false)
rescue ArgumentError => e
  puts "#{e.class}: #{e.message}"
end
# => ArgumentError: wrong number of arguments (given 2, expected 1)
# Un keyword argument ne se passe jamais par position : il faut écrire with_seats: false

puts format_session({ title: "Reliure japonaise", capacity: 1, registrants: [], status: :published })
# => Reliure japonaise [PUBLISHED] 1 place restante

# --- 1.6 Méthodes prédicats ---

def full?(session)
  remaining_seats(session) <= 0
end

def published?(session)
  session[:status] == :published
end

def open?(session)
  published?(session) && !full?(session)
end

watercolor = { title: "Aquarelle en plein air", capacity: 3, registrants: ["David", "Emma", "Fanny"], status: :published }

puts full?(session)             # => false
puts full?(watercolor)          # => true
puts published?(new_session)    # => false
puts open?(session)             # => true
puts open?(watercolor)          # => false

# --- 1.7 Truthiness ---

# Des variables plutôt que des littéraux, pour éviter l'avertissement "string literal in condition"
zero_string = "0"
false_string = "false"

puts "la chaîne \"0\" est vraie" if zero_string       # => la chaîne "0" est vraie
puts "0.0 est vrai" if 0.0                             # => 0.0 est vrai
puts "un hash vide est vrai" if {}                     # => un hash vide est vrai
puts "la chaîne \"false\" est vraie" if false_string   # => la chaîne "false" est vraie

# Seuls nil et false sont faux. Tout le reste est vrai.
# En PHP, "0", 0.0 et un tableau vide sont faux.

def has_registrants_buggy?(session)
  if session.fetch(:registrants, [])
    true
  else
    false
  end
end

sourdough = { title: "Pain au levain", capacity: 8, registrants: [], status: :draft }

puts has_registrants_buggy?(session)     # => true
puts has_registrants_buggy?(sourdough)   # => true (le bug : [] est vrai)

# Correction : on teste le contenu, et on renvoie directement l'expression.
def has_registrants?(session)
  session.fetch(:registrants, []).any?
end

puts has_registrants?(session)     # => true
puts has_registrants?(sourdough)   # => false

# --- 1.8 Plusieurs sessions ---

sessions = [
  { title: "Initiation à la céramique", capacity: 12, registrants: ["Alice", "Bruno", "Chloé"], status: :published },
  { title: "Aquarelle en plein air", capacity: 3, registrants: ["David", "Emma", "Fanny"], status: :published },
  { title: "Pain au levain", capacity: 8, registrants: [], status: :draft },
  { title: "Photo de rue", capacity: 10, registrants: ["Gaëlle", "Hugo"], status: :cancelled }
]

# Le bloc voit et modifie total, défini en dehors de lui.
def open_remaining_seats(sessions)
  total = 0
  sessions.each do |session|
    total += remaining_seats(session) if open?(session)
  end
  total
end

puts "--- Toutes les sessions ---"
sessions.each do |session|
  puts format_session(session)
end
# => Initiation à la céramique [PUBLISHED] 9 places restantes
# => Aquarelle en plein air [PUBLISHED] 0 places restantes
# => Pain au levain [DRAFT] 8 places restantes
# => Photo de rue [CANCELLED] 8 places restantes

puts "\n--- Sessions ouvertes ---"
sessions.each do |session|
  puts format_session(session) if open?(session)
end
# => Initiation à la céramique [PUBLISHED] 9 places restantes

puts "Places restantes dans les sessions ouvertes : #{open_remaining_seats(sessions)}"
# => Places restantes dans les sessions ouvertes : 9

sessions << { title: "Reliure japonaise", capacity: 6, registrants: [], status: :published }

puts "\n--- Sessions ouvertes après ajout ---"
sessions.each do |session|
  puts format_session(session) if open?(session)
end
# => Initiation à la céramique [PUBLISHED] 9 places restantes
# => Reliure japonaise [PUBLISHED] 6 places restantes

puts "Places restantes dans les sessions ouvertes : #{open_remaining_seats(sessions)}"
# => Places restantes dans les sessions ouvertes : 15
