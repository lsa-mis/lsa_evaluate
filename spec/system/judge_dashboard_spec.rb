require 'rails_helper'

RSpec.describe 'Judge Dashboard', type: :system do
  let(:judge) { create(:user, first_name: 'John', last_name: 'Doe', email: 'judge+gmail.com@umich.edu') }
  let(:judge_role) { create(:role, :judge) }
  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, container: container) }
  let(:contest_instance) { create(:contest_instance, contest_description: contest_description) }

  before do
    create(:user_role, user: judge, role: judge_role)
    create(:assignment, user: judge, container: container, role: judge_role)
    create(:judging_assignment, user: judge, contest_instance: contest_instance)
    sign_in judge
    visit judge_dashboard_path
  end

  it 'displays the judge information correctly' do
    expect(page).to have_content('Judge Dashboard')
    expect(page).to have_content("Welcome #{judge.first_name} #{judge.last_name} (#{judge.email})")
  end
end