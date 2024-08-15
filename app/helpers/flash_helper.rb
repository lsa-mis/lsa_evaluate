# frozen_string_literal: true

module FlashHelper
  FLASH_CLASSES = {
    alert: 'flash_alert',
    notice: 'flash_notice',
    success: 'flash_success',
    error: 'flash_error'
  }.freeze

  def css_class_for_flash(type)
    FLASH_CLASSES[type.to_sym] || 'flash_notice'
  end
end
