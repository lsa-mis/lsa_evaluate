# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Containers active applicants report', type: :request do
  let(:department) { create(:department) }
  let(:container) { create(:container, department: department, name: 'Hopwood Collection') }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description, active: true) }
  let(:admin) { create(:user, :axis_mundi) }

  before { sign_in admin }

  def create_report_entry!(last_name:, first_name:, email: nil)
    user = create(:user, last_name: last_name, first_name: first_name, email: email || "#{last_name.downcase}@umich.edu")
    profile = create(:profile, user: user)
    create(:entry, contest_instance: contest_instance, profile: profile)
    profile
  end

  it 'downloads a CSV of active applicants for the selected contest descriptions' do
    create_report_entry!(last_name: 'Zebra', first_name: 'Ann', email: 'zebra@umich.edu')
    create_report_entry!(last_name: 'Alpha', first_name: 'Zoe', email: 'alpha@umich.edu')

    get active_applicants_report_container_path(container, format: :csv),
        params: { contest_description_ids: [contest_description.id] }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('text/csv')
    expect(response.headers['Content-Disposition']).to include('active-applicants-in-hopwood-collection')

    csv = CSV.parse(response.body)
    expect(csv[0]).to eq(['Last Name', 'First Name', 'Email'])
    expect(csv[1]).to eq(['Alpha', 'Zoe', 'alpha@umich.edu'])
    expect(csv[2]).to eq(['Zebra', 'Ann', 'zebra@umich.edu'])
  end

  it 'neutralizes formula-like IdP names and emails in the CSV' do
    create_report_entry!(last_name: '=1+2', first_name: '+Ann', email: '=formula@umich.edu')
    create_report_entry!(last_name: '-Doe', first_name: 'Zoe', email: '+tagged@umich.edu')

    get active_applicants_report_container_path(container, format: :csv),
        params: { contest_description_ids: [contest_description.id] }

    expect(response).to have_http_status(:ok)

    csv = CSV.parse(response.body)
    expect(csv).to include(["'=1+2", "'+Ann", "'=formula@umich.edu"])
    expect(csv).to include(["'-Doe", 'Zoe', "'+tagged@umich.edu"])
  end

  it 'redirects with an alert when no contest descriptions are selected' do
    get active_applicants_report_container_path(container, format: :csv),
        params: { contest_description_ids: [] }

    expect(response).to redirect_to(reports_container_path(container))
    expect(flash[:alert]).to eq('Please select at least one contest description.')
  end

  it 'denies access for users without container authorization' do
    sign_in create(:user, :student)

    get active_applicants_report_container_path(container, format: :csv),
        params: { contest_description_ids: [contest_description.id] }

    expect(flash[:alert]).to eq('!!! Not authorized !!!')
  end
end
