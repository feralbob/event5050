require "administrate/base_dashboard"

class DrawDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    draw_date: Field::Date,
    prize_pool: Field::String.with_options(searchable: false),
    raffle: Field::BelongsTo,
    status: Field::Select.with_options(collection: Draw.statuses.keys),
    ticket_sales_end_at: Field::DateTime,
    ticket_sales_start_at: Field::DateTime,
    tickets: Field::HasMany,
    total_revenue: MoneyField,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    raffle
    draw_date
    status
    total_revenue
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    draw_date
    prize_pool
    raffle
    status
    ticket_sales_end_at
    ticket_sales_start_at
    tickets
    total_revenue
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    draw_date
    prize_pool
    raffle
    status
    ticket_sales_end_at
    ticket_sales_start_at
    tickets
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how draws are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(draw)
    "#{draw.raffle.name} - #{draw.draw_date}"
  end
end
