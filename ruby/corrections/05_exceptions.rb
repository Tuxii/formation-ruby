# ============================================
# Correction 5 - Gestion des erreurs et exceptions
# ============================================

# --- 5.2 La hiérarchie d'erreurs ---

class RegistrationError < StandardError
end

class SessionFullError < RegistrationError
  attr_reader :session

  def initialize(session)
    @session = session
    seats = session.capacity > 1 ? "places" : "place"
    super("#{session.title} est complète (#{session.capacity} #{seats})")
  end
end

class AlreadyRegisteredError < RegistrationError
  attr_reader :participant, :session

  def initialize(participant, session)
    @participant = participant
    @session = session
    super("#{participant.name} a déjà une inscription à #{session.title}")
  end
end

# --- Modules et classes repris du 04, sans rien retirer ---

module Publishable
  def publish
    @published = true
  end

  def unpublish
    @published = false
  end

  def published?
    @published == true
  end
end

module Describable
  def summary
    <<~TEXT
      #{title}
      #{"-" * title.length}
      #{description}
    TEXT
  end
end

module Numberable
  def next_number
    @last_number = (@last_number || 0) + 1
  end
end

class Session
  include Publishable
  include Describable
  include Enumerable
  extend Numberable

  attr_reader :title, :status, :registrations, :workshop, :starts_at, :number
  attr_accessor :capacity

  # --- 5.1 Une capacité qui n'en est pas une ---

  def initialize(title, capacity, workshop: nil, starts_at: nil)
    unless capacity.is_a?(Integer) && capacity.positive?
      raise ArgumentError, "la capacité doit être un entier positif (reçu : #{capacity.inspect})"
    end

    @title = title
    @capacity = capacity
    @workshop = workshop
    @starts_at = starts_at
    @status = :draft
    @registrations = []
    @number = self.class.next_number
  end

  def each(&block)
    registrations.each(&block)
  end

  def filter_registrations(&criterion)
    registrations.select(&criterion)
  end

  def confirmed_registrations
    filter_registrations { |r| r.confirmed? }
  end

  def waitlisted_registrations
    filter_registrations { |r| r.waitlisted? }
  end

  def cancelled_registrations
    filter_registrations { |r| r.cancelled? }
  end

  def remaining_seats
    capacity - count(&:confirmed?)
  end

  def full?
    remaining_seats <= 0
  end

  def publish
    super
    @status = :published
  end

  # --- 5.2 register! lève, register renvoie un booléen ---

  # Le doublon d'abord, la jauge ensuite
  def register!(participant)
    raise AlreadyRegisteredError.new(participant, self) if already_registered?(participant)
    raise SessionFullError.new(self) if full?

    registration = Registration.new(participant, self, :confirmed, Time.now)
    registrations << registration
    registration
  end

  # Même convention que save / save! en Rails
  def register(participant)
    register!(participant)
    true
  rescue RegistrationError
    false
  end

  def description
    workshop ? workshop.description : ""
  end

  def to_s
    "#{title} [#{status}] #{remaining_seats}/#{capacity} places libres"
  end

  def self.statuses
    [:draft, :published, :full, :cancelled, :finished]
  end

  private

  def already_registered?(participant)
    any? { |r| r.participant == participant && !r.cancelled? }
  end
end

class Workshop
  include Publishable
  include Describable

  attr_reader :title, :sessions
  attr_accessor :description, :duration_minutes

  def initialize(title, duration_minutes:, description: "")
    @title = title
    @duration_minutes = duration_minutes
    @description = description
    @sessions = []
  end

  def formatted_duration
    hours, minutes = duration_minutes.divmod(60)
    return "#{minutes} min" if hours.zero?
    return "#{hours} h" if minutes.zero?

    "#{hours} h #{minutes.to_s.rjust(2, "0")}"
  end

  def schedule(capacity:, starts_at:)
    session = Session.new(title, capacity, workshop: self, starts_at: starts_at)
    @sessions << session
    session
  end

  def total_seats
    sessions.sum { |session| session.capacity }
  end

  def to_s
    "#{title} (#{formatted_duration})"
  end
end

class OnlineSession < Session
  attr_reader :video_link

  def initialize(title, capacity, video_link)
    super(title, capacity)
    @video_link = video_link
  end

  def full?
    false
  end

  def to_s
    "#{super} - en ligne : #{video_link}"
  end
end

class Participant
  attr_reader :name, :email

  def initialize(name, email)
    @name = name
    @email = email
  end

  def to_s
    "#{name} <#{email}>"
  end
end

class Registration
  attr_reader :participant, :session, :status, :registered_at

  def initialize(participant, session, status, registered_at)
    @participant = participant
    @session = session
    @status = status
    @registered_at = registered_at
  end

  def confirmed?
    status == :confirmed
  end

  def waitlisted?
    status == :waitlisted
  end

  def cancelled?
    status == :cancelled
  end

  def to_s
    "#{participant.name} (#{status})"
  end
end

alice = Participant.new("Alice Martin", "alice@exemple.fr")
bruno = Participant.new("Bruno Petit", "bruno@exemple.com")
chloe = Participant.new("Chloé Durand", "chloe@exemple.fr")

# --- 5.1 Tests ---

# Sans la validation, Session.new("...", "12") passe, et remaining_seats lève plus tard :
# NoMethodError: undefined method '-' for an instance of String

# Dans un bloc do...end, rescue s'écrit sans begin.
["12", 0].each do |capacity|
  Session.new("Initiation à la céramique", capacity)
rescue ArgumentError => e
  puts "#{e.class}: #{e.message}"
end
# => ArgumentError: la capacité doit être un entier positif (reçu : "12")
# => ArgumentError: la capacité doit être un entier positif (reçu : 0)

puts Session.new("Initiation à la céramique", 12)
# => Initiation à la céramique [draft] 12/12 places libres

# capacity = "12" passe : l'écrivain généré par attr_accessor ne vérifie rien,
# et remaining_seats lèvera plus tard. Il faudrait écrire capacity= à la main.

# --- 5.2 Tests ---

session = Session.new("Initiation à la céramique", 2)
p session.register(alice)    # => true
p session.register(alice)    # => false

[alice, bruno, chloe, alice].each do |participant|
  puts session.register!(participant)
rescue RegistrationError => e
  puts "#{e.class}: #{e.message}"
end
# => AlreadyRegisteredError: Alice Martin a déjà une inscription à Initiation à la céramique
# => Bruno Petit (confirmed)
# => SessionFullError: Initiation à la céramique est complète (2 places)
# => AlreadyRegisteredError: Alice Martin a déjà une inscription à Initiation à la céramique
# (la dernière : complète, mais le doublon est vérifié d'abord)

# --- 5.3 Attraper au bon niveau ---

puts "\n--- 5.3 a. rescue ciblés ---"
session = Session.new("Initiation à la céramique", 2)
[alice, bruno, alice, chloe].each do |participant|
  begin
    session.register!(participant)
    puts "#{participant.name} : inscription confirmée"
  rescue SessionFullError => e
    puts "#{participant.name} : désolé, #{e.session.title} est complète"
  rescue AlreadyRegisteredError => e
    puts "#{e.participant.name} : déjà inscrite, rien à faire"
  end
end
# => Alice Martin : inscription confirmée
# => Bruno Petit : inscription confirmée
# => Alice Martin : déjà inscrite, rien à faire
# => Chloé Durand : désolé, Initiation à la céramique est complète

puts "\n--- 5.3 b. rescue du parent ---"
session = Session.new("Initiation à la céramique", 2)
[alice, bruno, alice, chloe].each do |participant|
  begin
    session.register!(participant)
    puts "#{participant.name} : inscription confirmée"
  rescue RegistrationError => e
    puts "#{participant.name} : #{e.message}"
  end
end
# => Alice Martin : inscription confirmée
# => Bruno Petit : inscription confirmée
# => Alice Martin : Alice Martin a déjà une inscription à Initiation à la céramique
# => Chloé Durand : Initiation à la céramique est complète (2 places)
# On gagne : un seul rescue, qui attrapera aussi les futures sous-classes.
# On perd : un traitement différent par cas.

puts "\n--- 5.3 c. rescue trop large ---"
begin
  session = Session.new("Aquarelle en plein air", 3)
  session.register!(alice)
  puts "Bienvenue #{alice.nmae}"
rescue => e
  puts "Inscription refusée"
end
p session.count
# => Inscription refusée
# => 1
# Alice EST inscrite, mais on lui dit le contraire : la faute de frappe (nmae) lève
# une NoMethodError, qui est une StandardError, et rescue => e la maquille en refus.
# Règle : attraper la classe d'erreur la plus précise possible, jamais Exception.

# --- 5.4 else et ensure ---

puts "\n--- 5.4 a. else ---"
# Une erreur levée dans le else n'est pas attrapée par le rescue : la faute de frappe éclate.
# (Le begin extérieur sert seulement à laisser le script continuer.)
begin
  begin
    session = Session.new("Aquarelle en plein air", 3)
    session.register!(alice)
  rescue => e
    puts "Inscription refusée"
  else
    puts "Bienvenue #{alice.nmae}"
  end
rescue NoMethodError => e
  puts "#{e.class}: #{e.message}"
end
# => NoMethodError: undefined method 'nmae' for an instance of Participant

puts "\n--- 5.4 b. ensure ---"

def register_all(session, participants)
  log = { succeeded: [], refused: [] }

  participants.each do |participant|
    session.register!(participant)
  rescue RegistrationError => e
    log[:refused] << e.message
  else
    log[:succeeded] << participant.name
  end

  log
ensure
  puts "Guichet fermé"
end

session = Session.new("Initiation à la céramique", 2)
p register_all(session, [alice, bruno, alice, chloe])
# => Guichet fermé
# => {succeeded: ["Alice Martin", "Bruno Petit"], refused: ["Alice Martin a déjà une inscription à Initiation à la céramique", "Initiation à la céramique est complète (2 places)"]}
# L'ensure s'exécute avant que p n'affiche le résultat.

begin
  register_all(Session.new("Aquarelle en plein air", 3), [alice, nil])
rescue NoMethodError => e
  puts "L'erreur remonte jusqu'à l'appelant : #{e.message}"
end
# => Guichet fermé
# => L'erreur remonte jusqu'à l'appelant : undefined method 'name' for nil
# nil.name lève dans le else : rescue RegistrationError ne l'attrape pas,
# l'erreur sort de la méthode, et l'ensure s'exécute quand même.

# --- 5.5 Relancer une exception ---

def register_with_logging(session, participant, log)
  session.register!(participant)
rescue RegistrationError => e
  log << "#{e.class} : #{e.message}"
  raise
end

puts "\n--- 5.5 ---"
log = []
session = Session.new("Pain au levain", 1)
register_with_logging(session, alice, log)
begin
  register_with_logging(session, bruno, log)
rescue SessionFullError => e
  puts "L'appelant décide : proposer une autre date pour #{e.session.title}"
end
p log
# => L'appelant décide : proposer une autre date pour Pain au levain
# => ["SessionFullError : Pain au levain est complète (1 place)"]

# Sans le raise, la méthode renvoie la valeur du rescue : le tableau log.
def register_without_raise(session, participant, log)
  session.register!(participant)
rescue RegistrationError => e
  log << "#{e.class} : #{e.message}"
end

p register_without_raise(session, chloe, [])
# => ["SessionFullError : Pain au levain est complète (1 place)"]
# Un tableau est truthy : l'appelant croit à un succès. L'erreur est avalée.
