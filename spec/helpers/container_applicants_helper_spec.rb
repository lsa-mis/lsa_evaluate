# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContainerApplicantsHelper, type: :helper do
  before do
    helper.instance_variable_set(:@available_years, [ 2026, 2024 ])
    helper.instance_variable_set(:@name_filter, 'Ada')
    helper.instance_variable_set(:@campus_id_filter, '')
    helper.instance_variable_set(:@selected_year, 'active')
  end

  describe '#year_filter_options' do
    it 'includes active, all years, and available years' do
      expect(helper.year_filter_options).to include(
        [ 'Active year', 'active' ],
        [ 'All years', 'all' ],
        [ '2026', '2026' ],
        [ '2024', '2024' ]
      )
    end
  end

  describe '#filter_query' do
    it 'omits blank campus filters' do
      expect(helper.filter_query).to eq(name: 'Ada', year: 'active')
    end
  end
end
