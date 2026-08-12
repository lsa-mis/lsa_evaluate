# frozen_string_literal: true

module EntriesHelper
  def entry_answer_display(entry, system_key_or_question)
    question = if system_key_or_question.is_a?(ApplicationQuestion)
                 system_key_or_question
               else
                 entry.contest_instance.contest_description.container
                      .application_questions.find_by(system_key: system_key_or_question)
               end
    return '—' unless question

    answer = entry.answer_for(question) || entry.entry_answers.find_by(application_question: question)
    return '—' unless answer

    answer.display_value.presence || '—'
  end

  def effective_question_headers(contest_instance)
    EffectiveApplicationQuestions.for(contest_instance).map(&:question)
  end
end
