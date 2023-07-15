class Contract < Tree
  include ActiveModel::Conversion
  extend ActiveModel::Translation

  attribute :starts_on, :ends_on

  def persisted?
    true
  end

  def self.model_name
    ActiveModel::Name.new(self)
  end

  def model_name
    self.class.model_name
  end

  def year
    @col[:year].to_i
  end

  def ends_on
    @col[:ends_on].try(:to_date)
  end

  def starts_on
    @col[:starts_on].try(:to_date)
  end
end
