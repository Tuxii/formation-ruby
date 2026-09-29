# ============================================
# Correction 3 - Héritage et modules
# ============================================
# Lancez depuis ruby/ : ruby corrections/03_heritage_modules.rb

# --- Modules ---

module Publishable
  def publish
    @published = true
  end

  def unpublish
    @published = false
  end

  # @published jamais affecté vaut nil : comparer à true garantit true ou false
  def published?
    @published == true
  end
end

module Describable
  # Contrat implicite : la classe qui inclut le module doit fournir title et description
  def summary
    <<~TEXT
      #{title}
      #{"-" * title.length}
      #{description}
    TEXT
  end
end

module Numberable
  # Ajoutée avec extend : self est la classe, @last_number appartient à la classe
  def next_number
    @last_number = (@last_number || 0) + 1
  end
end

# --- Classes ---

class Session
  include Publishable
  include Describable
  extend Numberable

  attr_reader :title, :status, :registrants, :workshop, :starts_at, :number
  attr_accessor :capacity

  def initialize(title, capacity, workshop: nil, starts_at: nil)
    @title = title
    @capacity = capacity
    @workshop = workshop
    @starts_at = starts_at
    @status = :draft
    @registrants = []
    @number = self.class.next_number
  end

  def remaining_seats
    capacity - registrants.size
  end

  def full?
    remaining_seats <= 0
  end

  # 3.2 : published? vient de Publishable ; super appelle Publishable#publish
  def publish
    super
    @status = :published
  end

  def register(name)
    return false if full? || already_registered?(name)

    registrants << name
    true
  end

  # 3.3 : Describable a besoin de description, on délègue à l'atelier
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

  def already_registered?(name)
    registrants.include?(name)
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
    total = 0
    sessions.each { |session| total += session.capacity }
    total
  end

  def to_s
    "#{title} (#{formatted_duration})"
  end
end

# --- 3.1 OnlineSession (héritage) ---

class OnlineSession < Session
  attr_reader :video_link

  def initialize(title, capacity, video_link)
    # super seul transmet les 3 arguments reçus, super() n'en transmet aucun
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

# --- Tests ---

ceramics = Workshop.new("Initiation à la céramique", duration_minutes: 90,
                        description: "Modeler, tourner, émailler, et repartir avec son bol.")
saturday = ceramics.schedule(capacity: 6, starts_at: Time.new(2026, 10, 10, 9, 30))

# 3.1 OnlineSession
# Avec super seul dans initialize :
# ArgumentError: wrong number of arguments (given 3, expected 2)

colors = OnlineSession.new("Théorie des couleurs", 2, "https://visio.exemple.fr/couleurs")
puts colors
# => Théorie des couleurs [draft] 2/2 places libres - en ligne : https://visio.exemple.fr/couleurs
colors.publish
puts colors.register("Alice")   # => true
puts colors.register("Bruno")   # => true
puts colors.register("Chloé")   # => true
puts colors
# => Théorie des couleurs [published] -1/2 places libres - en ligne : https://visio.exemple.fr/couleurs
# -1 place libre : redéfinir remaining_seats (dont full? dépend) aurait été plus juste.

# 3.2 Publishable

p Workshop.new("Pain au levain", duration_minutes: 120).published?   # => false
# (nil si published? renvoie @published tel quel)

ceramics.publish
puts ceramics.published?    # => true

saturday.publish
p saturday.status        # => :published
p saturday.published?    # => true
# Sans super : :published puis false, car Session#publish masque Publishable#publish

p Session.ancestors
# => [Session, Describable, Publishable, Object, Kernel, BasicObject]
p saturday.method(:publish).owner
# => Session
p saturday.method(:published?).owner
# => Publishable
p saturday.method(:publish).super_method
# => #<Method: Publishable#publish() corrections/03_heritage_modules.rb:9>

# 3.3 Describable

puts ceramics.summary
# => Initiation à la céramique
# => -------------------------
# => Modeler, tourner, émailler, et repartir avec son bol.

puts saturday.summary
# => (la même fiche, par délégation à l'atelier)
# Avant d'ajouter Session#description :
# NameError: undefined local variable or method 'description' for an instance of Session

# 3.4 Numberable

p Session.respond_to?(:next_number)    # => true
p saturday.respond_to?(:next_number)   # => false
a = Session.new("Croquis express", 8)
b = Session.new("Croquis express", 8)
p b.number - a.number                  # => 1
p saturday.number                      # => 1
p colors.number                        # => 1
# Dans next_number, self est la classe qui reçoit l'appel : Session, ou OnlineSession
# pour colors. Chaque classe a son propre @last_number : deux numérotations séparées.

# 3.5 Chaîne d'héritage et duck typing

p OnlineSession.ancestors
# => [OnlineSession, Session, Describable, Publishable, Object, Kernel, BasicObject]
# Un module inclus se place juste après la classe ; le dernier inclus est consulté en premier.

p colors.is_a?(Session)          # => true
p colors.is_a?(Publishable)      # => true
p colors.instance_of?(Session)   # => false

def print_catalog(items)
  items.each do |item|
    if item.respond_to?(:summary)
      puts item.summary
    else
      puts "(ignoré : #{item.inspect} n'a pas de fiche)"
    end
    puts
  end
end

print_catalog([ceramics, saturday, "une chaîne", 42])
# => les deux fiches, puis :
# => (ignoré : "une chaîne" n'a pas de fiche)
# => (ignoré : 42 n'a pas de fiche)
