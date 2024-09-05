# == Schema Information
#
# Table name: affiliations
#
#  id         :bigint           not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_affiliations_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
# ================================================================================================
# eduPersonAffiliation	umichInstRoles (in MCommunity)
# -------------------------------------------------------
# [student]   Student, EnrolledStudent
# [faculty]   Faculty
# [staff]   RegularStaff
# [employee]    Faculty, RegularStaff, TemporaryStaff
# [alum]    Alumni
# [affiliate]   SponsoredAffiliate
# [member]    Student, EnrolledStudent, Faculty, RegularStaff, TemporaryStaff, Retiree, Alumni
# # ================================================================================================

class Affiliation < ApplicationRecord
  belongs_to :user
  validates :name, presence: true
end