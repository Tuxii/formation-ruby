# ============================================
# Correction 4 - Blocs, itérateurs et Enumerable
# ============================================

# --- Modules (repris du 03) ---

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

# --- Classes (reprises du 03, puis modifiées en 4.5 et 4.6) ---

class Session
  include Publishable
  include Describable
  include Enumerable   # 4.6
  extend Numberable

  # 4.6 : @registrants a disparu, il ne reste que @registrations
  attr_reader :title, :status, :registrations, :workshop, :starts_at, :number
  attr_accessor :capacity

  def initialize(title, capacity, workshop: nil, starts_at: nil)
    @title = title
    @capacity = capacity
    @workshop = workshop
    @starts_at = starts_at
    @status = :draft
    @registrations = []
    @number = self.class.next_number
  end

  # 4.6 : le contrat d'Enumerable, comme dans 1-ruby.pdf, section 4
  def each(&block)
    registrations.each(&block)
  end

  # --- 4.5 Trois méthodes qui se ressemblent ---

  # Étape 1, le critère devient un bloc appelé avec yield :
  #
  # def filter_registrations
  #   result = []
  #   registrations.each do |registration|
  #     result << registration if yield(registration)
  #   end
  #   result
  # end
  #
  # Étape 2, le bloc est transmis tel quel à select :
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

  # --- 4.6 Le ménage, avec les méthodes d'Enumerable ---

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

  def register(participant)
    return false if full? || already_registered?(participant)

    registrations << Registration.new(participant, self, :confirmed, Time.now)
    true
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

  # 4.3 : la boucle avec accumulateur devient une ligne
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

# --- Participant et Registration (fournis) ---

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

# --- Données de travail ---

ceramics = Workshop.new("Initiation à la céramique", duration_minutes: 180)
watercolor = Workshop.new("Aquarelle en plein air", duration_minutes: 120)

saturday = ceramics.schedule(capacity: 5, starts_at: Time.new(2026, 10, 10, 9, 30))
tuesday = ceramics.schedule(capacity: 4, starts_at: Time.new(2026, 10, 13, 18, 30))
sunday = watercolor.schedule(capacity: 3, starts_at: Time.new(2026, 10, 11, 14, 0))

alice = Participant.new("Alice Martin", "alice@exemple.fr")
bruno = Participant.new("Bruno Petit", "bruno@exemple.com")
chloe = Participant.new("Chloé Durand", "chloe@exemple.fr")
david = Participant.new("David Leroy", "david@exemple.com")
emma = Participant.new("Emma Moreau", "emma@exemple.fr")
fanny = Participant.new("Fanny Bertin", "fanny@exemple.com")
gaelle = Participant.new("Gaëlle Roux", "gaelle@exemple.fr")
hugo = Participant.new("Hugo Lambert", "hugo@exemple.com")

registrations = [
  Registration.new(alice, saturday, :confirmed, Time.new(2026, 9, 1, 9, 12)),
  Registration.new(bruno, saturday, :confirmed, Time.new(2026, 9, 1, 12, 40)),
  Registration.new(chloe, saturday, :confirmed, Time.new(2026, 9, 2, 8, 5)),
  Registration.new(david, saturday, :cancelled, Time.new(2026, 9, 2, 21, 30)),
  Registration.new(emma, saturday, :confirmed, Time.new(2026, 9, 3, 10, 0)),
  Registration.new(fanny, saturday, :confirmed, Time.new(2026, 9, 4, 18, 45)),
  Registration.new(gaelle, saturday, :waitlisted, Time.new(2026, 9, 5, 7, 55)),
  Registration.new(david, tuesday, :confirmed, Time.new(2026, 9, 3, 9, 0)),
  Registration.new(hugo, tuesday, :confirmed, Time.new(2026, 9, 6, 14, 20)),
  Registration.new(alice, sunday, :confirmed, Time.new(2026, 9, 2, 13, 10)),
  Registration.new(chloe, sunday, :confirmed, Time.new(2026, 9, 2, 13, 15)),
  Registration.new(emma, sunday, :cancelled, Time.new(2026, 9, 3, 11, 30)),
  Registration.new(hugo, sunday, :confirmed, Time.new(2026, 9, 4, 9, 0)),
  Registration.new(bruno, sunday, :waitlisted, Time.new(2026, 9, 5, 16, 0))
]

registrations.each { |registration| registration.session.registrations << registration }

# --- 4.1 each et map ---

p [1, 2, 3].each { |n| n * 10 }   # => [1, 2, 3] (each renvoie le tableau d'origine)
p [1, 2, 3].map { |n| n * 10 }    # => [10, 20, 30] (map renvoie les résultats du bloc)

lines = registrations.map { |r| "#{r.participant.name}, #{r.registered_at.strftime('%d/%m à %Hh%M')}" }
puts lines
# => Alice Martin, 01/09 à 09h12
# => Bruno Petit, 01/09 à 12h40
# => ... (14 lignes)

# --- 4.2 Chercher ---

ines = registrations.find { |r| r.participant.name.start_with?("Inès") }
p ines   # => nil

begin
  puts ines&.participant.name
rescue NoMethodError => e
  puts "#{e.class}: #{e.message}"
end
# => NoMethodError: undefined method 'name' for nil
# Un &. ne protège que l'appel qui le suit : il en faut deux.

puts ines&.participant&.name || "Aucune inscription pour Inès"
# => Aucune inscription pour Inès

# --- 4.3 Calculer et regrouper ---

puts ceramics.total_seats   # => 9 (réécrit avec sum, voir Workshop)

by_status = registrations.each_with_object(Hash.new(0)) do |registration, counter|
  counter[registration.status] += 1
end
p by_status
# => {confirmed: 10, cancelled: 2, waitlisted: 2}

p registrations.map { |r| r.status }.tally
# => {confirmed: 10, cancelled: 2, waitlisted: 2}

by_session = registrations.group_by { |r| r.session }
p by_session.class   # => Hash (session => ses inscriptions)

by_session.each do |session, list|
  puts "#{session.title}, le #{session.starts_at.strftime('%d/%m')} : #{list.size} inscriptions"
end
# => Initiation à la céramique, le 10/10 : 7 inscriptions
# => Initiation à la céramique, le 13/10 : 2 inscriptions
# => Aquarelle en plein air, le 11/10 : 5 inscriptions

# --- 4.4 Chaîner ---

regulars = registrations
  .reject { |r| r.cancelled? }                      # tableau d'inscriptions
  .group_by { |r| r.participant }                   # hash : participant => ses inscriptions
  .select { |participant, list| list.size >= 2 }    # hash
  .map { |participant, list| participant.name }     # tableau de noms
  .sort
p regulars
# => ["Alice Martin", "Bruno Petit", "Chloé Durand", "Hugo Lambert"]

ceramics_registrations = ceramics.sessions.flat_map { |s| s.registrations }
p ceramics_registrations.size   # => 9
p ceramics_registrations.map { |r| r.participant.name }.uniq
# => ["Alice Martin", "Bruno Petit", "Chloé Durand", "David Leroy", "Emma Moreau", "Fanny Bertin", "Gaëlle Roux", "Hugo Lambert"]
# En Rails : has_many :registrations, through: :sessions

# --- 4.5 Trois méthodes qui se ressemblent ---

p saturday.confirmed_registrations.size    # => 5
p saturday.waitlisted_registrations.size   # => 1
p saturday.cancelled_registrations.size    # => 1

before_the_3rd = saturday.filter_registrations { |r| r.registered_at < Time.new(2026, 9, 3) }
p before_the_3rd.map { |r| r.participant.name }
# => ["Alice Martin", "Bruno Petit", "Chloé Durand", "David Leroy"]

dot_fr = saturday.filter_registrations { |r| r.participant.email.end_with?(".fr") }
p dot_fr.map { |r| r.participant.name }
# => ["Alice Martin", "Chloé Durand", "Emma Moreau", "Gaëlle Roux"]

# --- 4.6 Une session qui se parcourt ---

p saturday.count                                             # => 7 (toutes les inscriptions, pas les places prises)
p saturday.map { |r| r.participant.name }.first(3)           # => ["Alice Martin", "Bruno Petit", "Chloé Durand"]
p saturday.min_by { |r| r.registered_at }.participant.name   # => "Alice Martin"

p Enumerable.instance_methods.size   # => 61, gagnées en définissant each

puts saturday   # => Initiation à la céramique [draft] 0/5 places libres
puts tuesday    # => Initiation à la céramique [draft] 2/4 places libres
ines = Participant.new("Inès Garnier", "ines@exemple.fr")
puts tuesday.register(ines)    # => true
puts tuesday.register(ines)    # => false (déjà inscrite)
puts saturday.register(ines)   # => false (complète)
puts tuesday    # => Initiation à la céramique [draft] 1/4 places libres

# --- 4.7 &:symbole, Proc et lambda ---

p registrations.map(&:status).first(3)   # => [:confirmed, :confirmed, :confirmed]
p registrations.count(&:confirmed?)      # => 10

confirmed_check = :confirmed?.to_proc
p confirmed_check.call(registrations.first)   # => true

early_bird = Proc.new { |r| r.registered_at < Time.new(2026, 9, 2) }
p registrations.count(&early_bird)                  # => 2
p saturday.filter_registrations(&early_bird).size   # => 2

rate = ->(session) { session.count(&:confirmed?) * 100 / session.capacity }
p rate.call(tuesday)   # => 75 (Inès vient de s'inscrire)

begin
  rate.call(tuesday, saturday)
rescue ArgumentError => e
  puts "#{e.class}: #{e.message}"
end
# => ArgumentError: wrong number of arguments (given 2, expected 1)

rate_proc = Proc.new { |session| session.count(&:confirmed?) * 100 / session.capacity }
p rate_proc.call(tuesday, saturday)   # => 75 (le Proc ignore l'argument en trop)
