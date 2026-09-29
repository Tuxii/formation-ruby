# ============================================
# Correction 6 - Métaprogrammation
# ============================================

class Session
  STATUSES = [:draft, :published, :cancelled]

  attr_reader :title, :capacity, :status

  def initialize(title, capacity, status = :draft)
    @title = title
    @capacity = capacity
    @status = status
  end

  # --- 6.1 define_method ---

  # À la main, trois méthodes presque identiques :
  #
  #   def draft?
  #     @status == :draft
  #   end
  #
  #   def published?
  #     @status == :published
  #   end
  #
  #   def cancelled?
  #     @status == :cancelled
  #   end
  #
  # Avec une boucle, une seule écriture :
  STATUSES.each do |status|
    define_method("#{status}?") do
      @status == status
    end
  end
end

ceramics = Session.new("Initiation à la céramique", 12, :published)
bread = Session.new("Pain au levain", 8)

p ceramics.published?                  # => true
p bread.draft?                         # => true
p Session.instance_methods(false).sort
# => [:cancelled?, :capacity, :draft?, :published?, :status, :title]

# Ajouter :full à STATUSES suffit à créer full? : rien d'autre à écrire.

# --- 6.2 send ---

wanted = :published
p ceramics.send("#{wanted}?")          # => true

def sessions_with_status(sessions, status)
  sessions.select { |session| session.send("#{status}?") }
end

p sessions_with_status([ceramics, bread], :draft).map(&:title)
# => ["Pain au levain"]

p ceramics.send(:title)                # => "Initiation à la céramique"

# --- 6.3 method_missing ---

class Catalog
  def initialize(sessions)
    @sessions = sessions
  end

  def method_missing(name, *args)
    if name.start_with?("find_by_")
      attribute = name.to_s.delete_prefix("find_by_")
      @sessions.find { |session| session.send(attribute) == args.first }
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    name.start_with?("find_by_") || super
  end
end

catalog = Catalog.new([ceramics, bread])
p catalog.find_by_title("Pain au levain").capacity   # => 8
p catalog.find_by_capacity(12).title                 # => "Initiation à la céramique"
p catalog.find_by_status(:cancelled)                 # => nil

begin
  catalog.hello
rescue NoMethodError => e
  puts e.message
end
# => undefined method 'hello' for an instance of Catalog
# super passe la main au method_missing d'origine, qui lève NoMethodError

p catalog.methods.include?(:find_by_title)         # => false : la méthode n'existe nulle part
p catalog.respond_to?(:find_by_title)              # => true (grâce à respond_to_missing?)

# --- 6.4 D'où vient cette méthode ? ---

p ceramics.method(:published?).owner               # => Session
p ceramics.method(:title).owner                    # => Session
p ceramics.method(:frozen?).owner                  # => Kernel
p Session.ancestors                                # => [Session, Object, Kernel, BasicObject]

# --- 6.5 Classes ouvertes (bonus) ---

class String
  def shout
    upcase + " !"
  end
end

p "bonjour".shout                                  # => "BONJOUR !"
p "bonjour".method(:shout).owner                   # => String
