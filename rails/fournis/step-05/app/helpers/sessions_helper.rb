module SessionsHelper
  STATUS_LABELS = {
    "draft" => "Brouillon",
    "published" => "Publiée",
    "full" => "Complète",
    "cancelled" => "Annulée"
  }.freeze

  STATUS_COLORS = {
    "draft" => "secondary",
    "published" => "success",
    "full" => "warning",
    "cancelled" => "danger"
  }.freeze

  def status_badge(session)
    tag.span(STATUS_LABELS.fetch(session.status), class: "badge text-bg-#{STATUS_COLORS.fetch(session.status)}")
  end

  def status_options
    STATUS_LABELS.invert
  end
end
