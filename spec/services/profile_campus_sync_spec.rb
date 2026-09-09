# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfileCampusSync do
  let(:container) { create(:container) }
  let(:campus) { create(:campus) }
  let(:profile) { create(:profile, campus: nil) }
  let(:entry) { create(:entry, profile: profile) }
  let(:campus_question) { container.application_questions.find_by!(system_key: 'campus') }

  it 'writes a campus answer onto the profile' do
    answer = EntryAnswer.new(entry: entry, application_question: campus_question, value: campus.id)

    described_class.call(profile: profile, answers: [answer])

    expect(profile.reload.campus_id).to eq(campus.id)
  end

  it 'does not clear an existing campus when the answer is blank' do
    existing = create(:campus)
    profile.update!(campus: existing)
    answer = EntryAnswer.new(entry: entry, application_question: campus_question, value: nil)

    described_class.call(profile: profile, answers: [answer])

    expect(profile.reload.campus_id).to eq(existing.id)
  end
end
