module PageObjects
  class ContestInstanceElement
    def initialize(page, contest_instance)
      @page = page
      @contest_instance = contest_instance
    end

    def expand
      @page.find('.accordion-button', text: @contest_instance.contest_description.name).click
    end

    def expanded?
      @page.has_css?('.accordion-collapse.show')
    end

    def rated_entries_area
      @page.find("[data-entry-drag-target='ratedEntries']")
    end

    def available_entries_area
      @page.find("[data-entry-drag-target='availableEntries']")
    end

    def drag_entry_card_to_rated_entries_area(entry_card)
      drag_handle = entry_card.find('.drag-handle')
      drag_handle.drag_to(rated_entries_area)
    end

    def entry_card_count
      @page.all('.card').count
    end
  end
end
