# == Schema Information
#
# Table name: visibilities
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe Visibility, type: :model do
  describe 'validations' do
    it 'validates presence of kind' do
      visibility = Visibility.new(kind: nil)
      visibility.validate
      expect(visibility).not_to be_valid
    end
  end

  describe 'schema' do
    it 'has the correct columns' do
      columns = Visibility.column_names
      expect(columns).to include('id')
      expect(columns).to include('description')
      expect(columns).to include('kind')
      expect(columns).to include('created_at')
      expect(columns).to include('updated_at')
    end
  end
end
