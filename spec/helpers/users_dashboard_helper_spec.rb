# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersDashboardHelper, type: :helper do
  describe '#sort_link' do
    before do
      allow(helper).to receive(:params).and_return({})
      allow(helper).to receive(:request).and_return(double(query_parameters: {}))
      allow(helper).to receive(:users_dashboard_index_path).and_return('#')
    end

    it 'generates a link with correct data attributes' do
      link = helper.sort_link('email', 'Email Address')
      expect(link).to have_css('a[data-sort="email"]')
      expect(link).to have_content('Email Address')
    end

    it 'uses titleized column name when title is not provided' do
      link = helper.sort_link('email')
      expect(link).to have_content('Email')
    end

    context 'when column is currently sorted' do
      before do
        allow(helper).to receive(:params).and_return(sort: 'email', direction: 'asc')
      end

      it 'shows ascending icon when sorted ascending' do
        link = helper.sort_link('email')
        expect(link).to have_css('.bi-caret-up-fill')
      end

      it 'shows descending icon when sorted descending' do
        allow(helper).to receive(:params).and_return(sort: 'email', direction: 'desc')
        link = helper.sort_link('email')
        expect(link).to have_css('.bi-caret-down-fill')
      end
    end

    it 'generates a link with correct href attributes' do
      link = helper.sort_link('principal_name', 'Principal Name')
      expect(link).to have_css('a[data-sort="principal_name"]')
      expect(link).to have_content('Principal Name')
    end
  end

  describe '#sort_icon' do
    it 'returns empty string when column is not being sorted' do
      allow(helper).to receive(:params).and_return(sort: 'other_column')
      expect(helper.send(:sort_icon, 'email')).to be_empty
    end

    it 'returns up arrow for ascending sort' do
      allow(helper).to receive(:params).and_return(sort: 'email', direction: 'asc')
      icon = helper.send(:sort_icon, 'email')
      expect(icon).to have_css('.bi-caret-up-fill')
    end

    it 'returns down arrow for descending sort' do
      allow(helper).to receive(:params).and_return(sort: 'email', direction: 'desc')
      icon = helper.send(:sort_icon, 'email')
      expect(icon).to have_css('.bi-caret-down-fill')
    end
  end
end
