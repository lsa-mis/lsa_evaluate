class BulkContestInstanceForm
  include ActiveModel::Model

  attr_accessor :date_open, :date_closed

  validates :date_open, presence: true
  validates :date_closed, presence: true
end
