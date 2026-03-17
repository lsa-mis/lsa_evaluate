module ContestDescriptionsHelper
  def contest_description_entries_link(description)
    first_active = description.contest_instances.detect(&:active?)
    return nil unless first_active

    entry_count = first_active.entries.reject(&:deleted).size
    link_to("Active: #{pluralize(entry_count, 'entry')}",
            container_contest_description_contest_instance_path(description.container, description, first_active),
            class: 'btn btn-sm btn-primary small')
  end

  def contest_description_summary(description)
    total_instances = description.contest_instances.count
    active_instances = description.contest_instances.select(&:active?)
    summary = ''
    if active_instances.any?
      summary += contest_description_entries_link(description).to_s
      summary += '<br>'
    end
    summary += "<small>#{pluralize(total_instances, 'instance')}</small>"

    content_tag(:div, summary.html_safe, class: 'text-muted')
  end
end
