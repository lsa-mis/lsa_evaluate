# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContestInstancesHelper, type: :helper do
  describe '#contest_instance_setup_steps' do
    it 'marks earlier steps complete and the current step current' do
      steps = helper.contest_instance_setup_steps(:review_process)

      expect(steps.map { |step| [ step[:key], step[:state] ] }).to eq(
        [
          [ :contest_details, :complete ],
          [ :questions, :complete ],
          [ :review_process, :current ],
          [ :dashboard, :upcoming ]
        ]
      )
    end
  end
end
