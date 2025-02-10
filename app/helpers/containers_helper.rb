module ContainersHelper
  def contest_description_action_links(container, description)
    {
      view: {
        path: container_contest_description_contest_instances_path(container, description),
        icon: 'eye',
        title: 'View instances'
      },
      edit: {
        path: edit_container_contest_description_path(container, description),
        icon: 'pencil',
        title: 'Edit contest'
      },
      archive: {
        path: container_contest_description_path(container, description),
        icon: 'archive',
        title: 'Archive contest',
        data: {
          method: :delete,
          controller: 'confirm',
          confirm_message_value: 'Are you sure you want to archive this?'
        }
      }
    }
  end

  def render_eligibility_rules(description)
    eligibility_plain = description.eligibility_rules.to_plain_text
    if eligibility_plain.length > 100
      content_tag(:div) do
        truncate(eligibility_plain, length: 100, omission: '') +
        link_to('...more', '#',
          data: {
            action: 'click->modal#open',
            url: eligibility_rules_container_contest_description_path(description.container, description),
            modal_title: 'Eligibility Rules'
          }
        )
      end
    else
      description.eligibility_rules
    end
  end

  def render_description(container)
    description_plain = container.description.to_plain_text
    if description_plain.length > 100
      content_tag(:div) do
        truncate(description_plain, length: 100, omission: '') +
        link_to('...more', '#',
          data: {
            action: 'click->modal#open',
            url: description_container_path(container),
            modal_title: 'Description'
          }
        )
      end
    else
      container.description
    end
  end
end
