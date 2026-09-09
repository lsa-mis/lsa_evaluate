# frozen_string_literal: true

class ProfileCampusSync
  def self.call(profile:, answers:)
    new(profile: profile, answers: answers).call
  end

  def initialize(profile:, answers:)
    @profile = profile
    @answers = Array(answers)
  end

  def call
    campus_id = campus_id_from_answers
    return @profile if campus_id.blank? || @profile.campus_id == campus_id

    @profile.update!(campus_id: campus_id)
    @profile
  end

  private

  def campus_id_from_answers
    answer = @answers.find { |item| item.application_question&.field_type == 'campus' }
    return if answer.nil?

    campus_id = answer.respond_to?(:campus_id_value) ? answer.campus_id_value : answer.value.to_i
    campus_id if campus_id.present? && campus_id.positive? && Campus.exists?(id: campus_id)
  end
end
