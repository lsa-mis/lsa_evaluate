# spec/factories/statuses_spec.rb
require 'rails_helper'

RSpec.describe 'Status Factory' do
  it 'is valid' do
    expect(FactoryBot.build(:status)).to be_valid
  end
end
