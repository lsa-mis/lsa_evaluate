require 'rails_helper'

RSpec.describe 'Judge Round Visibility', type: :system do
  include ApplicationHelper

  let(:container) { create(:container) }
  let(:contest_description) { create(:contest_description, :active, container: container) }
  let(:contest_instance) { create(:contest_instance,
    contest_description: contest_description,
    date_open: 5.days.ago,
    date_closed: 3.days.ago
  ) }
  let(:judge) { create(:user, :with_judge_role) }

  let!(:round_1) do
    create(:judging_round,
      contest_instance: contest_instance,
      round_number: 1,
      active: true,
      start_date: 2.days.ago,
      end_date: 2.days.from_now
    )
  end

  let!(:round_2) do
    create(:judging_round,
      contest_instance: contest_instance,
      round_number: 2,
      active: false,
      start_date: 3.days.from_now,
      end_date: 5.days.from_now
    )
  end

  before do
    # Assign judge to contest instance
    create(:judging_assignment, user: judge, contest_instance: contest_instance, active: true)
    sign_in judge
  end

  context 'when judge is assigned to round 1 only' do
    before do
      travel_to(Time.current) do  # During round 1's active period
        create(:round_judge_assignment, user: judge, judging_round: round_1, active: true)
        visit judge_dashboard_path
      end
    end


    it 'shows round 1 information' do
      travel_to(Time.current) do
        expect(page).to have_content("Round: #{round_1.round_number}")
        expect(page).to have_content(format_datetime(round_1.start_date))
        expect(page).to have_content(format_datetime(round_1.end_date))
      end
    end

    it 'allows access to round 1 judging interface' do
      travel_to(Time.current) do
        find('.accordion-button').click
        expect(page).to have_css('[data-controller="entry-drag"]')
      end
    end

    it 'does not show round 2 information' do
      travel_to(Time.current) do
        expect(page).to have_no_content("Round: #{round_2.round_number}")
      end
    end
  end

  context 'when judge is assigned to round 2 only' do
    before do
      travel_to(4.days.from_now) do  # During round 2's active period
        round_1.update!(active: false)
        round_2.update!(active: true)
        create(:round_judge_assignment, user: judge, judging_round: round_2, active: true)
        visit judge_dashboard_path
      end
    end


    it 'shows round 2 information' do
      travel_to(4.days.from_now) do
        expect(page).to have_content("Round: #{round_2.round_number}")
        expect(page).to have_content(format_datetime(round_2.start_date))
        expect(page).to have_content(format_datetime(round_2.end_date))
      end
    end

    it 'allows access to round 2 judging interface' do
      travel_to(4.days.from_now) do
        find('.accordion-button').click
        expect(page).to have_css('[data-controller="entry-drag"]')
      end
    end

    it 'does not show round 1 information' do
      travel_to(4.days.from_now) do
        expect(page).to have_no_content("Round: #{round_1.round_number}")
      end
    end
  end

  context 'when judge is not assigned to any rounds' do
    before do
      travel_to(1.day.from_now) do
        round_1.update!(active: true)  # Ensure round is active
        visit judge_dashboard_path
      end
    end

    it 'shows appropriate message for no round assignment' do
      travel_to(1.day.from_now) do
        expect(page).to have_content('No active rounds assigned to you')
      end
    end

    it 'does not show judging interface' do
      travel_to(1.day.from_now) do
        visit judge_dashboard_path  # Reload page within time travel block
        find('.accordion-button').click
        expect(page).to have_content('No active rounds assigned to you')
        expect(page).to have_no_css('[data-controller="entry-drag"]')
      end
    end
  end

  context 'when judge assignment is inactive' do
    before do
      travel_to(1.day.from_now) do
        round_1.update!(active: true)  # Ensure round is active
        create(:round_judge_assignment, user: judge, judging_round: round_1, active: false)
        visit judge_dashboard_path
      end
    end

    it 'shows appropriate message for no active assignment' do
      travel_to(1.day.from_now) do
        expect(page).to have_content('No active rounds assigned to you')
      end
    end

    it 'does not show judging interface' do
      travel_to(1.day.from_now) do
        visit judge_dashboard_path  # Reload page within time travel block
        find('.accordion-button').click
        expect(page).to have_content('No active rounds assigned to you')
        expect(page).to have_no_css('[data-controller="entry-drag"]')
      end
    end
  end
end
