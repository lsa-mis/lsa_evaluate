# == Schema Information
#
# Table name: statuses
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_statuses_on_kind  (kind) UNIQUE
#
require 'rails_helper'

RSpec.describe Status do
  let(:status) { build(:status_active) }

  describe 'validations' do
    it 'validates presence of kind' do
      status.kind = nil
      expect(status).not_to be_valid
      expect(status.errors[:kind]).to include("can't be blank")
    end

    it 'validates uniqueness of kind' do
      create(:status_active, kind: 'Active')
      status.kind = 'Active'
      expect(status).not_to be_valid
      expect(status.errors[:kind]).to include('has already been taken')
    end

    it 'validates inclusion of kind in specific values' do
      status.kind = 'InvalidKind'
      expect(status).not_to be_valid
      expect(status.errors[:kind]).to include('is not included in the list')
    end

    it 'validates presence of description' do
      status.description = nil
      expect(status).not_to be_valid
      expect(status.errors[:description]).to include("can't be blank")
    end
  end
end
