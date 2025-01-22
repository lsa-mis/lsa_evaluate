module PageObjects
  class ContestInstanceElement
    def initialize(page, contest_instance)
      @page = page
      @contest_instance = contest_instance
    end

    def expand
      @page.find('.accordion-button', text: @contest_instance.contest_description.name).click
    end
  end
end
