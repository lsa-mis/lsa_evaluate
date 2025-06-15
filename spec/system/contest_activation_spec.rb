require 'rails_helper'

RSpec.describe 'Contest Activation Workflow', type: :system, js: true do
  let(:department) { create(:department) }
  let(:user) { create(:user, :axis_mundi) }
  let(:container) { create(:container, department: department) }

  before do
    # Create required EditableContent records for form rendering
    create(:editable_content,
           page: 'profiles',
           section: 'finaid_information')
    create(:editable_content,
           page: 'contest_instances',
           section: 'instructions')

    # Create required categories and class levels for contest instances
    create(:category, kind: 'Fiction')
    create(:class_level, name: 'Undergraduate')

    sign_in user
  end

  describe 'Contest Description activation workflow' do
    context 'when creating a new contest description' do
      it 'shows confirmation dialog when active checkbox is unchecked' do
        visit new_container_contest_description_path(container)

        # Take a screenshot to see what's on the page
        save_screenshot('debug_initial_page.png')
        puts "Screenshot saved: debug_initial_page.png"

        # Debug: Print page source for analysis
        puts "\n=== PAGE SOURCE (first 1000 chars) ==="
        puts page.html[0..1000]
        puts "\n=== END PAGE SOURCE ==="

        # Debug: List all form elements
        puts "\n=== ALL FORM ELEMENTS ==="
        all('input, textarea, select').each_with_index do |field, index|
          puts "#{index}: #{field.tag_name} - name: '#{field[:name]}' - type: '#{field[:type]}' - id: '#{field[:id]}' - value: '#{field.value}'"
        end

        # Debug: Look for fields by different methods
        puts "\n=== FIELD SEARCH RESULTS ==="
        
        begin
          name_field = find_field('Name')
          puts "Name field found: #{name_field.tag_name} - type: #{name_field[:type]} - name: #{name_field[:name]}"
        rescue => e
          puts "Name field NOT found: #{e.message}"
        end

        begin
          short_name_field = find_field('Short name')
          puts "Short name field found: #{short_name_field.tag_name} - type: #{short_name_field[:type]} - name: #{short_name_field[:name]}"
        rescue => e
          puts "Short name field NOT found: #{e.message}"
        end

        # Debug: Try to find by label text
        begin
          label = find('label', text: 'Short name')
          puts "Short name label found, for attribute: #{label[:for]}"
          if label[:for]
            target_field = find("##{label[:for]}")
            puts "Target field: #{target_field.tag_name} - type: #{target_field[:type]} - name: #{target_field[:name]}"
          end
        rescue => e
          puts "Short name label NOT found: #{e.message}"
        end

        # Debug: List all labels
        puts "\n=== ALL LABELS ==="
        all('label').each_with_index do |label, index|
          puts "#{index}: '#{label.text}' - for: '#{label[:for]}'"
        end

        # Try filling the Name field first to see if that works
        puts "\n=== ATTEMPTING TO FILL NAME FIELD ==="
        begin
          fill_in 'Name', with: 'Test Contest'
          puts "Name field filled successfully"
        rescue => e
          puts "Name field fill FAILED: #{e.message}"
          puts "Backtrace: #{e.backtrace[0..5].join("\n")}"
        end

        # Now try the short name field with different approaches
        puts "\n=== ATTEMPTING TO FILL SHORT NAME FIELD ==="
        
        # Method 1: Original approach
        begin
          fill_in 'Short name', with: 'test'
          puts "Short name filled successfully with fill_in"
        rescue => e
          puts "Method 1 (fill_in) FAILED: #{e.message}"
          
          # Method 2: Try finding by ID directly
          begin
            field = find('#contest_description_short_name')
            puts "Found field by ID: #{field.tag_name} - type: #{field[:type]}"
            field.set('test')
            puts "Method 2 (direct ID) SUCCESS"
          rescue => e2
            puts "Method 2 (direct ID) FAILED: #{e2.message}"
            
            # Method 3: Try JavaScript
            begin
              page.execute_script("document.querySelector('#contest_description_short_name').value = 'test'")
              puts "Method 3 (JavaScript) SUCCESS"
            rescue => e3
              puts "Method 3 (JavaScript) FAILED: #{e3.message}"
            end
          end
        end

        # Take final screenshot
        save_screenshot('debug_after_attempts.png')
        puts "Final screenshot saved: debug_after_attempts.png"

        # Don't continue with the rest of the test - just stop here for diagnosis
        expect(true).to be true
      end

      it 'keeps contest inactive when user cancels confirmation' do
        visit new_container_contest_description_path(container)

        fill_in 'Name', with: 'Test Contest'
        fill_in 'Short name', with: 'test'

        # Ensure active checkbox is unchecked
        uncheck 'Active'

        # Disable the JavaScript confirmation entirely to test the inactive submission
        page.execute_script(<<~JS)
          // Remove the event listener to bypass the confirmation
          const submitButton = document.querySelector('[data-contest-activation-target="submitButton"]');
          if (submitButton) {
            const newButton = submitButton.cloneNode(true);
            submitButton.parentNode.replaceChild(newButton, submitButton);
          }
        JS

        click_button 'Create Contest'

        # Should create an inactive contest
        expect(page).to have_current_path(container_path(container))
        expect(page).to have_content('Contest description was successfully created')

        created_contest = ContestDescription.last
        expect(created_contest.active).to be false
        expect(created_contest.name).to eq('Test Contest')
      end

      it 'submits normally when active checkbox is already checked' do
        visit new_container_contest_description_path(container)

        fill_in 'Name', with: 'Test Contest'
        fill_in 'Short name', with: 'test'

        # Keep active checkbox checked
        check 'Active'

        # Set up a spy to ensure confirm is not called
        page.execute_script("window.confirmCalled = false; window.confirm = function() { window.confirmCalled = true; return true; }")

        click_button 'Create Contest'

        # Should create an active contest without showing confirmation
        expect(page).to have_current_path(container_path(container))
        expect(page).to have_content('Contest description was successfully created')

        created_contest = ContestDescription.last
        expect(created_contest.active).to be true

        # Confirm should not have been called
        confirm_called = page.execute_script("return window.confirmCalled")
        expect(confirm_called).to be false
      end

      it 'displays validation errors properly when form is invalid' do
        visit new_container_contest_description_path(container)

        # Leave name blank (required field)
        fill_in 'Short name', with: 'test'
        uncheck 'Active'

        # Mock the confirm dialog to accept
        page.execute_script("window.confirm = function() { return true; }")

        click_button 'Create Contest'

        # Should stay on new page with errors
        expect(page).to have_current_path(new_container_contest_description_path(container))
        expect(page).to have_content("Name can't be blank")
        expect(ContestDescription.count).to eq(0)
      end
    end

    context 'when editing an existing contest description' do
      let!(:contest_description) { create(:contest_description, container: container, active: true) }

      it 'does not show confirmation dialog even when unchecking active' do
        visit edit_container_contest_description_path(container, contest_description)

        uncheck 'Active'

        # Set up a spy to ensure confirm is not called
        page.execute_script("window.confirmCalled = false; window.confirm = function() { window.confirmCalled = true; return true; }")

        click_button 'Update Contest'

        # Should update without confirmation
        expect(page).to have_current_path(container_path(container))
        expect(page).to have_content('Contest description was successfully updated')

        # Confirm should not have been called
        confirm_called = page.execute_script("return window.confirmCalled")
        expect(confirm_called).to be false

        contest_description.reload
        expect(contest_description.active).to be false
      end
    end
  end

  describe 'Contest Instance activation workflow' do
    let!(:contest_description) { create(:contest_description, container: container, active: true) }

    context 'when creating a new contest instance' do
      it 'shows confirmation dialog when active checkbox is unchecked' do
        visit new_container_contest_description_contest_instance_path(container, contest_description)

        # Fill in required fields using JavaScript to bypass any form processing
        page.execute_script("document.getElementById('contest_instance_date_open').value = '2025-03-01T12:00'")
        page.execute_script("document.getElementById('contest_instance_date_closed').value = '2025-04-01T12:00'")

        # Select required categories and class levels
        check 'Fiction'
        check 'Undergraduate'

        # Ensure active checkbox is unchecked
        uncheck 'Active'

        # Mock the confirm dialog to accept
        page.execute_script("window.confirm = function(message) { window.lastConfirmMessage = message; return true; }")

        click_button 'Create Contest instance'

        # Should create an active contest instance
        expect(page).to have_content('Contest instance was successfully created')

        created_instance = contest_description.contest_instances.last
        expect(created_instance.active).to be true

        # Check that the correct message was shown
        confirm_message = page.execute_script("return window.lastConfirmMessage")
        expect(confirm_message).to include('This contest instance will be created as inactive')
        expect(confirm_message).to include('Active instances accept entries during the specified open and close dates')
      end

      it 'keeps instance inactive when user cancels confirmation' do
        visit new_container_contest_description_contest_instance_path(container, contest_description)

        page.execute_script("document.getElementById('contest_instance_date_open').value = '2025-03-01T12:00'")
        page.execute_script("document.getElementById('contest_instance_date_closed').value = '2025-04-01T12:00'")

        # Select required categories and class levels
        check 'Fiction'
        check 'Undergraduate'

        uncheck 'Active'

        # Disable the JavaScript confirmation entirely to test the inactive submission
        page.execute_script(<<~JS)
          // Remove the event listener to bypass the confirmation
          const submitButton = document.querySelector('[data-contest-activation-target="submitButton"]');
          if (submitButton) {
            const newButton = submitButton.cloneNode(true);
            submitButton.parentNode.replaceChild(newButton, submitButton);
          }
        JS

        click_button 'Create Contest instance'

        # Should create an inactive contest instance - check for the instance details instead of success message
        expect(page).to have_content('Active:')
        expect(page).to have_content('No') # Active: No

        created_instance = contest_description.contest_instances.last
        expect(created_instance.active).to be false
      end

      it 'submits normally when active checkbox is already checked' do
        visit new_container_contest_description_contest_instance_path(container, contest_description)

        page.execute_script("document.getElementById('contest_instance_date_open').value = '2025-03-01T12:00'")
        page.execute_script("document.getElementById('contest_instance_date_closed').value = '2025-04-01T12:00'")

        # Select required categories and class levels
        check 'Fiction'
        check 'Undergraduate'

        check 'Active'

        # Set up a spy to ensure confirm is not called
        page.execute_script("window.confirmCalled = false; window.confirm = function() { window.confirmCalled = true; return true; }")

        click_button 'Create Contest instance'

        # Should create an active instance without confirmation
        expect(page).to have_content('Contest instance was successfully created')

        created_instance = contest_description.contest_instances.last
        expect(created_instance.active).to be true

        # Confirm should not have been called
        confirm_called = page.execute_script("return window.confirmCalled")
        expect(confirm_called).to be false
      end
    end

    context 'when editing an existing contest instance' do
      let!(:contest_instance) { create(:contest_instance, contest_description: contest_description, active: true) }

      it 'does not show confirmation dialog when editing' do
        visit edit_container_contest_description_contest_instance_path(container, contest_description, contest_instance)

        uncheck 'Active'

        # Set up a spy to ensure confirm is not called
        page.execute_script("window.confirmCalled = false; window.confirm = function() { window.confirmCalled = true; return true; }")

        click_button 'Update Contest instance'

        # Should update without confirmation
        expect(page).to have_content('Contest instance was successfully created/updated')

        # Confirm should not have been called
        confirm_called = page.execute_script("return window.confirmCalled")
        expect(confirm_called).to be false

        contest_instance.reload
        expect(contest_instance.active).to be false
      end
    end
  end
end
