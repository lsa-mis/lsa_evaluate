# == Schema Information
#
# Table name: categories
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  kind        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe Category, type: :model do
  it { is_expected.to validate_presence_of(:kind) }
  it { is_expected.to validate_uniqueness_of(:kind) }

  it {
    expect(subject).to validate_inclusion_of(:kind).in_array(['Drama', 'Screenplay', 'Non-Fiction', 'Fiction', 'Poetry',
                                                              'Novel', 'Short Fiction', 'Text-Image'])
  }

  it { is_expected.to validate_presence_of(:description) }
end
