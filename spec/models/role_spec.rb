# == Schema Information
#
# Table name: roles
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe Role, type: :model do
  describe 'associations' do
    it 'has many user_roles with dependent destroy' do
      association = described_class.reflect_on_association(:user_roles)
      expect(association.macro).to eq :has_many
      expect(association.options[:dependent]).to eq :destroy
    end

    it 'has many users through user_roles' do
      association = described_class.reflect_on_association(:users)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :user_roles
    end

    it 'has many assignments with dependent destroy' do
      association = described_class.reflect_on_association(:assignments)
      expect(association.macro).to eq :has_many
      expect(association.options[:dependent]).to eq :destroy
    end

    it 'has many containers through assignments' do
      association = described_class.reflect_on_association(:containers)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :assignments
    end
  end

  describe 'schema' do
    it 'has the correct columns' do
      columns = Role.column_names
      expect(columns).to include('id')
      expect(columns).to include('description')
      expect(columns).to include('kind')
      expect(columns).to include('created_at')
      expect(columns).to include('updated_at')
    end
  end
end
