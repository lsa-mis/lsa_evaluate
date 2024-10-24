module ContestDescriptionsHelper
  def contest_description_summary(description)
    total_instances = description.contest_instances.count
    active_instances = description.contest_instances.where(active: true)
    summary = ''
    if active_instances.any?
      first_active = active_instances.first
      entry_count = first_active.entries.where(deleted: false).count
      summary += '<small class="text-nowrap">Active instance</small><br>'
      summary += link_to(pluralize(entry_count, 'entry'),
                         container_contest_description_contest_instance_path(description.container, description, first_active), class: 'btn btn-sm btn-primary')
      summary += '<br>'
    end
    summary += "<small>#{pluralize(total_instances, 'instance')}</small>"

    content_tag(:div, summary.html_safe, class: 'text-muted')
  end
end
