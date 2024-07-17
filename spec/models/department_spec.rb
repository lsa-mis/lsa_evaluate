# == Schema Information
#
# Table name: departments
#
#  id               :bigint           not null, primary key
#  dept_description :text(65535)
#  name             :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  dept_id          :integer          not null
#
require 'rails_helper'

RSpec.describe Department, type: :model do
  describe 'associations' do
    it 'has many containers with dependent destroy' do
      association = described_class.reflect_on_association(:containers)
      expect(association.macro).to eq :has_many
      expect(association.options[:dependent]).to eq :destroy
    end
  end

  describe 'validations' do
    it 'validates presence of name' do
      department = Department.new(name: nil)
      expect(department).not_to be_valid
      expect(department.errors[:name]).to include("can't be blank")
    end

    it 'validates presence of dept_id' do
      department = Department.new(dept_id: nil)
      expect(department).not_to be_valid
      expect(department.errors[:dept_id]).to include("can't be blank")
    end
  end

  describe 'schema' do
    it 'has the correct columns' do
      columns = Department.column_names
      expect(columns).to include('id')
      expect(columns).to include('dept_description')
      expect(columns).to include('name')
      expect(columns).to include('created_at')
      expect(columns).to include('updated_at')
      expect(columns).to include('dept_id')
    end
  end
end
