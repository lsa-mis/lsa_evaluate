# == Schema Information
#
# Table name: entries
#
#  id                  :bigint           not null, primary key
#  deleted             :boolean          default(FALSE), not null
#  disqualified        :boolean          default(FALSE), not null
#  title               :string(255)      not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  category_id         :bigint           not null
#  contest_instance_id :bigint           not null
#  profile_id          :bigint           not null
#
# Indexes
#
#  category_id_idx                       (category_id)
#  contest_instance_id_idx               (contest_instance_id)
#  id_unq_idx                            (id) UNIQUE
#  index_entries_on_category_id          (category_id)
#  index_entries_on_contest_instance_id  (contest_instance_id)
#  index_entries_on_profile_id           (profile_id)
#  profile_id_idx                        (profile_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (contest_instance_id => contest_instances.id)
#  fk_rails_...  (profile_id => profiles.id)
#
class Entry < ApplicationRecord
  belongs_to :contest_instance
  belongs_to :profile
  belongs_to :category
  has_one_attached :entry_file

  validates :title, presence: true
  validate :entry_file_validation

  scope :active, -> { where(deleted: false) }
  scope :disqualified, -> { where(disqualified: true) }

  def self.sortable_columns
    {
      'id' => 'entries.id',
      'title' => 'entries.title',
      'created_at' => 'entries.created_at',
      'profile_display_name' => 'profiles.last_name',
      'profile_user_uniqname' => 'users.uniqname',
      'pen_name' => 'profiles.pen_name',
      'disqualified' => 'entries.disqualified'
    }
  end

  def active_entry?
    !disqualified && !deleted
  end

  def entry_file_validation
    if entry_file.attached?
      # Validate file type
      acceptable_types = ["application/pdf"]
      unless acceptable_types.include?(entry_file.content_type)
        errors.add(:entry_file, "must be a PDF")
      end

      # Validate file size
      if entry_file.byte_size > 30.megabytes
        errors.add(:entry_file, "is too big. Maximum size is 30 MB.")
      end
    else
      errors.add(:entry_file, "can't be blank")
    end
  end

end
