# frozen_string_literal: true

module ContainerApplicantsHelper
  def year_filter_options
    options = [
      [ 'Active year', ContainerApplicantsQuery::YEAR_ACTIVE ],
      [ 'All years', ContainerApplicantsQuery::YEAR_ALL ]
    ]
    Array(@available_years).each do |year|
      options << [ year.to_s, year.to_s ]
    end
    options
  end

  def filter_query
    {
      name: @name_filter,
      campus_id: @campus_id_filter,
      year: @selected_year
    }.compact_blank
  end
end
