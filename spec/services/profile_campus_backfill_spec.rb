# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfileCampusBackfill do
  let(:container) { create(:container) }
  let(:campus) { create(:campus) }
  let(:profile) { create(:profile, campus: nil) }
  let(:entry) { create(:entry, profile: profile) }
  let(:campus_question) { container.application_questions.find_by!(system_key: 'campus') }

  it 'sets campus_id from the most recent campus answer' do
    EntryAnswer.create!(entry: entry, application_question: campus_question, value: campus.id)

    expect { described_class.call }.to change { profile.reload.campus_id }.from(nil).to(campus.id)
  end

  it 'leaves profiles without campus answers unchanged' do
    expect { described_class.call }.not_to change { profile.reload.campus_id }
  end
end
