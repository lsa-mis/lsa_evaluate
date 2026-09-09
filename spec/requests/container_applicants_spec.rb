# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection applicants directory', type: :request do
  let(:container) { create(:container, name: 'Hopwood Collection') }
  let(:contest_description) { create(:contest_description, :active, container: container, name: 'Poetry') }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description, active: true) }
  let(:campus) { create(:campus, campus_descr: 'Ann Arbor') }
  let(:admin) { create(:user, :axis_mundi) }

  before { sign_in admin }

  def create_applicant!(last_name:, first_name:, email: nil)
    user = create(:user, last_name: last_name, first_name: first_name, email: email || "#{last_name.downcase}@umich.edu")
    profile = create(:profile, user: user, legal_last_name: last_name, legal_first_name: first_name, campus: campus)
    create(:entry, contest_instance: contest_instance, profile: profile)
    profile
  end

  it 'renders the searchable applicant list' do
    profile = create_applicant!(last_name: 'Lovelace', first_name: 'Ada')

    get container_applicants_path(container)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Applicants for Hopwood Collection')
    expect(response.body).to include('Unique submitters')
    expect(response.body).to include(profile.display_name)
    expect(response.body).to include('Ann Arbor')
    expect(response.body).to include('Poetry')
  end

  it 'downloads a CSV of applicants for the current filters' do
    create_applicant!(last_name: 'Lovelace', first_name: 'Ada', email: 'ada@umich.edu')
    create_applicant!(last_name: '=1+2', first_name: '+Ann', email: '=formula@umich.edu')

    get container_applicants_path(container, format: :csv)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('text/csv')
    expect(response.headers['Content-Disposition']).to include('applicants-in-hopwood-collection')

    csv = CSV.parse(response.body)
    expect(csv[0]).to eq(
      [
        'Last Name', 'First Name', 'Display Name', 'Email', 'Uniqname', 'UMID',
        'Campus', 'Submission Count', 'Contests', 'Years', 'Finalist In'
      ]
    )
    expect(csv.any? { |row| row[0] == 'Lovelace' && row[3] == 'ada@umich.edu' && row[6] == 'Ann Arbor' }).to be true
    expect(csv.any? { |row| row[0] == "'=1+2" && row[1] == "'+Ann" && row[3] == "'=formula@umich.edu" }).to be true
  end

  it 'shows a collection-scoped applicant profile' do
    profile = create_applicant!(last_name: 'Lovelace', first_name: 'Ada')

    get container_applicant_path(container, profile)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(profile.display_name)
    expect(response.body).to include('Poetry')
    expect(response.body).to include('Ann Arbor')
  end

  it 'denies access for users without container authorization' do
    sign_in create(:user, :student)

    get container_applicants_path(container)

    expect(flash[:alert]).to eq('!!! Not authorized !!!')
  end
end
