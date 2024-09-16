module EntriesHelper
  def disqualified_icon(entry)
    if entry.disqualified
      content_tag(:i, '', class: 'bi bi-book', style: 'font-size: 1.5rem;', aria: { hidden: 'true' })
    else
      ''
    end
  end

  def archived_icon(entry)
    if entry.archived
      content_tag(:i, '', class: 'bi bi-book', style: 'font-size: 1.5rem;', aria: { hidden: 'true' })
    else
      ''
    end
  end
end
