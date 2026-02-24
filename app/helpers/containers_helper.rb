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
      }
    }
  end

  def render_eligibility_rules(description)
    eligibility_plain = description.eligibility_rules.to_plain_text.to_s.squish
    preview_words = eligibility_plain.split

    if preview_words.length > 6
      preview_text = preview_words.first(6).join(' ')

      content_tag(:div, class: 'd-inline-flex align-items-center gap-1 border rounded px-1 py-0 bg-light small') do
        safe_join([
          content_tag(:span, 'Rules:', class: 'fw-semibold text-muted'),
          content_tag(:span, preview_text, class: 'text-muted'),
          link_to('...more', '#',
            data: {
              action: 'click->modal#open',
              url: eligibility_rules_container_contest_description_path(description.container, description),
              modal_title: 'Eligibility Rules'
            },
            aria: { label: 'View full eligibility rules' }
          )
        ])
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
