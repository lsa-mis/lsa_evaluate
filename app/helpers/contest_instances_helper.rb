module ContestInstancesHelper
  SETUP_STEPS = [
    { key: :contest_details, label: 'Contest details' },
    { key: :questions, label: 'Questions' },
    { key: :review_process, label: 'Review process' },
    { key: :dashboard, label: 'Dashboard' }
  ].freeze

  def contest_instance_setup_steps(current_step)
    current_index = SETUP_STEPS.index { |step| step[:key] == current_step } || 0

    SETUP_STEPS.each_with_index.map do |step, index|
      state = if index < current_index
                :complete
              elsif index == current_index
                :current
              else
                :upcoming
              end

      step.merge(number: index + 1, state: state)
    end
  end

  def finaid_info_hint
    content = EditableContent.find_by(page: 'profiles', section: 'finaid_information').content.body.to_s
    safe_join([
      content,

      "External link: Learn more about financial aid terms and conditions on the Office of Financial Aid's website"
    ])
  end

  def contest_instance_active_tab
    allowed_tabs = %w[summary entries manage-judges judging-results]
    return params[:tab] if params[:tab].in?(allowed_tabs)
    return 'judging-results' if params[:sort_judge_id].present?

    'summary'
  end

  def contest_instance_tab_active?(tab_name)
    contest_instance_active_tab == tab_name
  end
end