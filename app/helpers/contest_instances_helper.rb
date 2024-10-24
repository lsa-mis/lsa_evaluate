module ContestInstancesHelper
  def finaid_info_hint
    content = EditableContent.find_by(page: 'profiles', section: 'finaid_information').content.body.to_s
    safe_join([
      content,

      "External link: Learn more about financial aid terms and conditions on the Office of Financial Aid's website"
    ])
  end
end