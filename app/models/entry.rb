# == Schema Information
#
# Table name: entries
#
#  id                  :bigint           not null, primary key
#  title               :string(255)      not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  category_id         :bigint           not null
#  contest_instance_id :bigint           not null
#  profile_id          :bigint           not null
#  status_id           :bigint           not null
#
# Indexes
#
#  category_id_idx                       (category_id)
#  contest_instance_id_idx               (contest_instance_id)
#  id_unq_idx                            (id) UNIQUE
#  index_entries_on_category_id          (category_id)
#  index_entries_on_contest_instance_id  (contest_instance_id)
#  index_entries_on_profile_id           (profile_id)
#  index_entries_on_status_id            (status_id)
#  profile_id_idx                        (profile_id)
#  status_id_idx                         (status_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (contest_instance_id => contest_instances.id)
#  fk_rails_...  (profile_id => profiles.id)
#  fk_rails_...  (status_id => statuses.id)
#
class Entry < ApplicationRecord
  belongs_to :status
  belongs_to :contest_instance
  belongs_to :profile
  belongs_to :category
  has_one_attached :entry_file

  validates :title, presence: true
end
