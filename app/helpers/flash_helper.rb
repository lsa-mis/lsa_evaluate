module FlashHelper
  def css_class_for_flash(type)
    case type.to_sym
    when :alert
      "flash_alert"
    else
      "flash_notice"
    end
  end
end