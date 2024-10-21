class DatetimeLocalInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    merged_input_options[:type] = 'datetime-local'
    merged_input_options[:value] = @builder.object.send(attribute_name)&.strftime('%Y-%m-%dT%H:%M')

    @builder.text_field(attribute_name, merged_input_options)
  end
end
