module EntriesHelper
  def disqualified_icon(entry)
    if entry.disqualified
      content_tag(:i, '', class: 'bi bi-eye', style: 'font-size: 1.5rem;', aria: { hidden: 'true' })
    else
      ''
    end
  end
end
