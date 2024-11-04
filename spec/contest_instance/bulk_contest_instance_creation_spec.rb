require 'rails_helper'

RSpec.describe "Bulk Contest Instance Creation", type: :feature do
  let(:container) { create(:container) }
  let!(:container_admin_role) { create(:role, kind: 'Collection Administrator') }
  let!(:container_admin) { create(:user) }
  let!(:container_admin_role_assignment) { create(:assignment, container: container, user: container_admin, role: container_admin_role) }

  let!(:contest_description1) { create(:contest_description, container: container) }
  let!(:contest_description2) { create(:contest_description, container: container) }

  let!(:existing_instance1) { create(:contest_instance, contest_description: contest_description1) }
  let!(:existing_instance2) { create(:contest_instance, contest_description: contest_description2) }

  before do
    login_as container_admin
  end

  describe "bulk creation workflow" do
    it "shows only contest descriptions that have existing instances" do
      visit new_container_bulk_contest_instance_path(container)

      expect(page).to have_content(contest_description1.name)
      expect(page).to have_content(contest_description2.name)

      # Create a new contest description without instances
      new_description = create(:contest_description, container: container)
      expect(page).to have_no_content(new_description.name)
    end

    it "allows selection of multiple contest descriptions" do
      visit new_container_bulk_contest_instance_path(container)

      check "contest_description_#{contest_description1.id}"
      check "contest_description_#{contest_description2.id}"

      expect(page).to have_field("contest_description_#{contest_description1.id}", checked: true)
      expect(page).to have_field("contest_description_#{contest_description2.id}", checked: true)
    end

    it "requires date selection" do
      visit new_container_bulk_contest_instance_path(container)

      check "contest_description_#{contest_description1.id}"
      click_button "Create Instances"

      expect(page).to have_content("Date open can't be blank")
      expect(page).to have_content("Date closed can't be blank")
    end

    it "creates new instances based on most recent existing instances" do
      new_open_date = 1.month.from_now
      new_close_date = 2.months.from_now

      visit new_container_bulk_contest_instance_path(container)

      check "contest_description_#{contest_description1.id}"
      fill_in "bulk_contest_instance_form[date_open]", with: new_open_date.strftime('%Y-%m-%dT00:00')
      fill_in "bulk_contest_instance_form[date_closed]", with: new_close_date.strftime('%Y-%m-%dT00:00')

      expect {
        click_button "Create Instances"
      }.to change(ContestInstance, :count).by(1)

      new_instance = contest_description1.contest_instances.last
      expect(new_instance.date_open.to_date).to eq(new_open_date.to_date)
      expect(new_instance.date_closed.to_date).to eq(new_close_date.to_date)
      expect(new_instance.categories).to match_array(existing_instance1.categories)
      expect(new_instance.class_levels).to match_array(existing_instance1.class_levels)
    end

    it "validates date ranges" do
      visit new_container_bulk_contest_instance_path(container)

      check "contest_description_#{contest_description1.id}"
      fill_in "bulk_contest_instance_form[date_open]", with: 1.day.from_now.strftime('%Y-%m-%dT00:00')
      fill_in "bulk_contest_instance_form[date_closed]", with: 1.day.ago.strftime('%Y-%m-%dT00:00')

      click_button "Create Instances"

      expect(page).to have_content("Date closed must be after date contest opens")
    end
  end
end
