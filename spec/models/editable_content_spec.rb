# == Schema Information
#
# Table name: editable_contents
#
#  id         :bigint           not null, primary key
#  page       :string(255)      not null
#  section    :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe EditableContent do
  subject { build(:editable_content) }

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:editable_content)).to be_valid
    end
  end

  describe 'validations' do
    it 'validates presence of page' do
      editable_content = build(:editable_content, page: nil)
      expect(editable_content).not_to be_valid
      expect(editable_content.errors[:page]).to include("can't be blank")
    end

    it 'validates presence of section' do
      editable_content = build(:editable_content, section: nil)
      expect(editable_content).not_to be_valid
      expect(editable_content.errors[:section]).to include("can't be blank")
    end

    it 'validates presence of content' do
      editable_content = build(:editable_content)
      editable_content.content = nil
      expect(editable_content).not_to be_valid
      expect(editable_content.errors[:content]).to include("can't be blank")
    end

    it 'validates uniqueness of page and section combination' do
      create(:editable_content, page: 'home', section: 'instructions')
      editable_content = build(:editable_content, page: 'home', section: 'instructions')
      expect(editable_content).not_to be_valid
      expect(editable_content.errors[:page]).to include('and section combination must be unique')
    end
  end

  describe 'associations' do
    # Add association tests here if there are any, for example:
    # it { should belong_to(:user) }
  end

  describe 'instance methods' do
    # Add tests for instance methods here if there are any, for example:
    # describe '#some_method' do
    #   it 'does something' do
    #     expect(subject.some_method).to eq(expected_result)
    #   end
    # end
  end
end
