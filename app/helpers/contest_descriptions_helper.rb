module ContestDescriptionsHelper
  def contest_description_entries_link(description)
    active_instances = description.contest_instances.where(active: true)
    return nil if active_instances.empty?

    first_active = active_instances.first
    entry_count = first_active.entries.where(deleted: false).count
    link_to("Active: #{pluralize(entry_count, 'entry')}",
            container_contest_description_contest_instance_path(description.container, description, first_active),
            class: 'btn btn-sm btn-primary small')
  end

  def contest_description_summary(description)
    total_instances = description.contest_instances.count
    active_instances = description.contest_instances.where(active: true)
    summary = ''
    if active_instances.any?
      summary += contest_description_entries_link(description).to_s
      summary += '<br>'
    end
    summary += "<small>#{pluralize(total_instances, 'instance')}</small>"

    content_tag(:div, summary.html_safe, class: 'text-muted')
  end
end
