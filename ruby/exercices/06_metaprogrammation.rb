# ============================================
# Exercice 6 - Métaprogrammation
# Ouvrez 06_metaprogrammation.md pour les consignes
# Lancez avec : ruby 06_metaprogrammation.rb
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

end

ceramics = Session.new("Initiation à la céramique", 12, :published)
bread = Session.new("Pain au levain", 8)

# --- 6.1 Vérifications ---

# --- 6.2 send ---

# --- 6.3 method_missing ---

# --- 6.4 D'où vient cette méthode ? ---

# --- 6.5 Classes ouvertes (bonus) ---
