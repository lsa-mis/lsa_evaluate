require 'rails_helper'

RSpec.describe "Bulk Contest Instance Creation", type: :system do
  describe "bulk creation workflow" do
    before do
      @container = create(:container)
      @admin_role = create(:role, kind: 'Collection Administrator')
      @admin = create(:user)
      create(:assignment, container: @container, user: @admin, role: @admin_role)
      login_as @admin
    end

    it "shows only contest descriptions that have existing instances" do
      description1 = create(:contest_description, :active, container: @container)
      description2 = create(:contest_description, :active, container: @container)
      create(:contest_instance, contest_description: description1)
      create(:contest_instance, contest_description: description2)

      visit new_container_bulk_contest_instance_path(@container)

      expect(page).to have_content(description1.name)
      expect(page).to have_content(description2.name)

      # Create a new contest description without instances
      new_description = create(:contest_description, :active, container: @container)
      expect(page).to have_no_content(new_description.name)
    end

    it "allows selection of multiple contest descriptions" do
      description1 = create(:contest_description, :active, container: @container)
      description2 = create(:contest_description, :active, container: @container)
      create(:contest_instance, contest_description: description1)
      create(:contest_instance, contest_description: description2)

      visit new_container_bulk_contest_instance_path(@container)

      check "contest_description_#{description1.id}"
      check "contest_description_#{description2.id}"

      expect(page).to have_field("contest_description_#{description1.id}", checked: true)
      expect(page).to have_field("contest_description_#{description2.id}", checked: true)
    end

    it "requires date selection" do
      description = create(:contest_description, :active, container: @container)
      create(:contest_instance, contest_description: description)

      visit new_container_bulk_contest_instance_path(@container)

      check "contest_description_#{description.id}"
      click_button "Create Instances"

      expect(page).to have_content("Date open can't be blank")
      expect(page).to have_content("Date closed can't be blank")
    end

    it "creates new instances based on most recent existing instances" do
      description = create(:contest_description, :active, container: @container)
      existing_instance = create(:contest_instance, contest_description: description)
      new_open_date = 1.month.from_now
      new_close_date = 2.months.from_now

      visit new_container_bulk_contest_instance_path(@container)

      check "contest_description_#{description.id}"
      fill_in "bulk_contest_instance_form[date_open]", with: new_open_date.strftime('%Y-%m-%dT00:00')
      fill_in "bulk_contest_instance_form[date_closed]", with: new_close_date.strftime('%Y-%m-%dT00:00')

      expect {
        click_button "Create Instances"
      }.to change(ContestInstance, :count).by(1)

      new_instance = description.contest_instances.last
      expect(new_instance.date_open.to_date).to eq(new_open_date.to_date)
      expect(new_instance.date_closed.to_date).to eq(new_close_date.to_date)
      expect(new_instance.categories).to match_array(existing_instance.categories)
      expect(new_instance.class_levels).to match_array(existing_instance.class_levels)
    end

    it "validates date ranges" do
      description = create(:contest_description, :active, container: @container)
      create(:contest_instance, contest_description: description)

      visit new_container_bulk_contest_instance_path(@container)

      check "contest_description_#{description.id}"
      fill_in "bulk_contest_instance_form[date_open]", with: 1.day.from_now.strftime('%Y-%m-%dT00:00')
      fill_in "bulk_contest_instance_form[date_closed]", with: 1.day.ago.strftime('%Y-%m-%dT00:00')

      click_button "Create Instances"

      expect(page).to have_content("Date closed must be after date contest opens")
    end
  end
end
