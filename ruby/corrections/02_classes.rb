# ============================================
# Correction 2 - Les classes
# ============================================
# Les lignes qui lèvent une erreur volontairement sont entourées de begin / rescue
# (exercice 5) pour que le script aille jusqu'au bout.
# Lancez depuis ruby/ : ruby corrections/02_classes.rb

# --- 2.1 La classe Session, à la main ---

# Version à la main gardée sous un autre nom, pour la comparer à Session au 2.2.
class HandwrittenSession
  def initialize(title, capacity)
    @title = title
    @capacity = capacity
    @status = :draft
    @registrants = []
  end

  def title
    @title
  end

  def capacity
    @capacity
  end

  def capacity=(new_capacity)
    @capacity = new_capacity
  end

  def status
    @status
  end

  def registrants
    @registrants
  end
end

session = HandwrittenSession.new("Initiation à la céramique", 12)
puts session.title        # => Initiation à la céramique
session.capacity = 14
puts session.capacity     # => 14
session.capacity=(15)
puts session.capacity     # => 15
# session.capacity = 14 est un appel de la méthode capacity=
p session.status          # => :draft
p session
# => #<HandwrittenSession:0x... @title="Initiation à la céramique", @capacity=15, @status=:draft, @registrants=[]>

begin
  session.status = :published
rescue NoMethodError => e
  puts "#{e.class}: #{e.message}"
end
# => NoMethodError: undefined method 'status=' for an instance of HandwrittenSession
# Le signe égal fait partie du nom de la méthode.

# --- 2.2 Avant la refacto ---

p HandwrittenSession.instance_methods(false).sort
# => [:capacity, :capacity=, :registrants, :status, :title]
p HandwrittenSession.instance_method(:title).source_location
# => ["corrections/02_classes.rb", 19] : la ligne du def title

# --- 2.2 à 2.5 La classe Session ---

class Session
  # 2.2 : ces deux lignes génèrent les méthodes écrites à la main au 2.1, sans def
  # (workshop et starts_at sont ajoutés au 2.7)
  attr_reader :title, :status, :registrants, :workshop, :starts_at
  attr_accessor :capacity

  def initialize(title, capacity, workshop: nil, starts_at: nil)
    @title = title
    @capacity = capacity
    @workshop = workshop
    @starts_at = starts_at
    @status = :draft
    @registrants = []
  end

  # --- 2.3 Prédicats et calculs ---

  # capacity sans self : receveur implicite, Ruby appelle self.capacity
  def remaining_seats
    capacity - registrants.size
  end

  def full?
    remaining_seats <= 0
  end

  def published?
    status == :published
  end

  # --- 2.4 Méthodes d'action ---

  # status = :published      => crée une variable locale, le statut ne change pas
  # self.status = :published => NoMethodError, il n'existe pas de méthode status=
  # Solution 1 (retenue) : écrire la variable d'instance
  # Solution 2 : attr_writer :status sous private, puis self.status = :published
  def publish
    @status = :published
  end

  def register(name)
    return false if full? || already_registered?(name)

    registrants << name
    true
  end

  def to_s
    "#{title} [#{status}] #{remaining_seats}/#{capacity} places libres"
  end

  # --- 2.5 Méthode de classe ---

  def self.statuses
    [:draft, :published, :full, :cancelled, :finished]
  end

  private

  def already_registered?(name)
    registrants.include?(name)
  end
end

# --- 2.2 Après la refacto ---

p Session.instance_methods(false).sort
# => [:capacity, :capacity=, :full?, :publish, :published?, :register, :registrants, :remaining_seats, :starts_at, :status, :title, :to_s, :workshop]
# (au 2.2, votre liste s'arrêtait aux 5 méthodes du 2.1)
p HandwrittenSession.instance_methods(false) - Session.instance_methods(false)
# => [] : toutes les méthodes du 2.1 existent aussi dans Session
p Session.instance_method(:title).source_location
# => ["corrections/02_classes.rb", 71] : la ligne de attr_reader, pas un def

# --- 2.3 Tests ---

bread = Session.new("Pain au levain", 8)
puts bread.remaining_seats   # => 8
puts bread.full?             # => false
puts bread.published?        # => false

# --- 2.4 Tests ---

session = Session.new("Aquarelle en plein air", 3)
session.publish
p session.status                 # => :published

begin
  session.status = :cancelled
rescue NoMethodError => e
  puts "#{e.class}: #{e.message}"
end
# => NoMethodError: undefined method 'status=' for an instance of Session
# (avec la solution 2 : private method 'status=' called for an instance of Session)

puts session.register("David")   # => true
puts session.register("David")   # => false
puts session                     # => Aquarelle en plein air [published] 2/3 places libres
# puts appelle to_s sur l'objet
puts session.register("Emma")    # => true
puts session.register("Fanny")   # => true
puts session.register("Gaëlle")  # => false

begin
  session.already_registered?("David")
rescue NoMethodError => e
  puts "#{e.class}: #{e.message}"
end
# => NoMethodError: private method 'already_registered?' called for an instance of Session

session.registrants << "Intrus"
puts session                     # => Aquarelle en plein air [published] -1/3 places libres
# registrants renvoie le tableau lui-même, pas une copie : << le modifie sans passer
# par register. « Lecture seule » protège la variable (pas de registrants=), pas le tableau.

# --- 2.5 Méthode de classe ---

p Session.statuses
# => [:draft, :published, :full, :cancelled, :finished]

begin
  session.statuses
rescue NoMethodError => e
  puts "#{e.class}: #{e.message}"
end
# => NoMethodError: undefined method 'statuses' for an instance of Session

p session.class.statuses
# => [:draft, :published, :full, :cancelled, :finished]

# --- 2.6 à 2.7 La classe Workshop ---

class Workshop
  attr_reader :title, :sessions
  attr_accessor :description, :duration_minutes

  def initialize(title, duration_minutes:, description: "")
    @title = title
    @duration_minutes = duration_minutes
    @description = description
    @published = false
    @sessions = []
  end

  def published?
    @published
  end

  def publish
    @published = true
  end

  def formatted_duration
    hours, minutes = duration_minutes.divmod(60)
    return "#{minutes} min" if hours.zero?
    return "#{hours} h" if minutes.zero?

    "#{hours} h #{minutes.to_s.rjust(2, "0")}"
  end

  # --- 2.7 Un atelier programme ses sessions ---

  # self, ici, c'est l'atelier sur lequel on a appelé schedule
  def schedule(capacity:, starts_at:)
    session = Session.new(title, capacity, workshop: self, starts_at: starts_at)
    @sessions << session
    session
  end

  def total_seats
    total = 0
    sessions.each { |session| total += session.capacity }
    total
  end

  def to_s
    "#{title} (#{formatted_duration})"
  end
end

# --- Tests Workshop ---

workshop = Workshop.new("Initiation à la céramique", duration_minutes: 90)
workshop.description = "Modeler, tourner, émailler, et repartir avec son bol."
puts workshop                  # => Initiation à la céramique (1 h 30)
puts workshop.published?       # => false
workshop.publish
puts workshop.published?       # => true
puts Workshop.new("Pain au levain", duration_minutes: 120).formatted_duration    # => 2 h
puts Workshop.new("Croquis express", duration_minutes: 45).formatted_duration    # => 45 min
puts Workshop.new("Reliure japonaise", duration_minutes: 65).formatted_duration  # => 1 h 05

begin
  Workshop.new("Croquis express")
rescue ArgumentError => e
  puts "#{e.class}: #{e.message}"
end
# => ArgumentError: missing keyword: :duration_minutes
# Un keyword argument sans valeur par défaut est obligatoire.

ceramics = Workshop.new("Initiation à la céramique", duration_minutes: 90)
saturday = ceramics.schedule(capacity: 6, starts_at: Time.new(2026, 10, 10, 9, 30))
tuesday = ceramics.schedule(capacity: 4, starts_at: Time.new(2026, 10, 13, 18, 30))

puts ceramics.sessions.size                        # => 2
puts ceramics.total_seats                          # => 10
puts saturday                                      # => Initiation à la céramique [draft] 6/6 places libres
puts saturday.workshop                             # => Initiation à la céramique (1 h 30)
puts saturday.starts_at.strftime("%d/%m à %Hh%M")  # => 10/10 à 09h30
