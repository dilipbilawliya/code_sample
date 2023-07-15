class Account < ApplicationRecord
  include ChangelogConcern
  attribute :timezone, :string, default: 'Eastern Time (US & Canada)'

  enum status: { active: 0, inactive: 1, suspended: 2 }, _prefix: :status

  belongs_to :client

  has_many :memberships,                        dependent: :delete_all
  has_many :users,                              through: :memberships
  has_many :invitations,                        dependent: :delete_all
  has_many :api_keys,                           dependent: :delete_all
  has_many :webhooks,                           dependent: :delete_all
  has_many :emails,                             dependent: :delete_all
  has_many :events,                             dependent: :delete_all
  has_many :customers,                          dependent: :delete_all
  has_many :domains,                            dependent: :delete_all
  has_many :integrations,                       dependent: :delete_all
  has_many :products,                           dependent: :delete_all
  has_many :orders,                             dependent: :delete_all
  has_many :roles,                              dependent: :delete_all
  has_many :inventory_locations,                dependent: :delete_all

  validates :name, presence: true, uniqueness: { scope: :client_id }, format: {
    with: /\A[a-z0-9-]+\z/,
    message: "only allows lower case letters, numbers and hyphens"
  }

  before_validation do
    self.name = self.name.to_s.downcase.gsub(/[^a-z0-9-]/, ' ').squish.tr(' ', '-')
  end

  def to_s
    self.name
  end

  def self.collection
    Account.joins(:client).order('name ASC').pluck("CONCAT(clients.name, ' - ', accounts.name) as name", 'accounts.id')
  end

  def as_json(options = nil)
    super({ include: [:client] }.merge(options || {}))
  end

  after_create do
    create_default_role
    create_default_inventory_location
  end

  def create_default_role
    ROLE_PERMISSIONS.each do |name, role_attrs|
      Role.create_with(role_attrs).find_or_create_by!(name: name, account_id: id)
    end
  end

  def create_default_inventory_location
    InventoryLocation.create_with(
      address1: self.client.address,
      city: self.client.city,
      state: self.client.state,
      country: self.client.country,
      zipcode: self.client.zipcode,
    ).find_or_create_by!(
      name: 'default',
      account_id: self.id
    )
  end

end
