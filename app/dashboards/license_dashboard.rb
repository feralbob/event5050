require "administrate/base_dashboard"

class LicenseDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    event_date: Field::Date,
    expires_at: Field::Date,
    issued_at: Field::Date,
    jurisdiction: Field::BelongsTo,
    license_number: Field::String,
    license_type: Field::Select.with_options(collection: License.license_types.keys),
    organization: Field::BelongsTo,
    recurrence_rule: Field::String,
    requirements: Field::String.with_options(searchable: false),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    license_number
    organization
    jurisdiction
    expires_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    event_date
    expires_at
    issued_at
    jurisdiction
    license_number
    license_type
    organization
    recurrence_rule
    requirements
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    event_date
    expires_at
    issued_at
    jurisdiction
    license_number
    license_type
    organization
    recurrence_rule
    requirements
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

  # Overwrite this method to customize how licenses are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(license)
    license.license_number
  end
end
