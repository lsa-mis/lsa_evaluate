# frozen_string_literal: true

require 'rails_helper'

# Active Storage 8.1 aborts boot when ruby-vips is installed and libvips is
# older than 8.13. This app only resizes Action Text images, via MiniMagick.
RSpec.describe ActiveStorage do
  it 'processes variants with MiniMagick' do
    expect(described_class.variant_processor).to eq(:mini_magick)
  end

  it 'loads MiniMagick' do
    expect(described_class::MINIMAGICK_AVAILABLE).to be(true)
  end

  it 'does not make libvips available' do
    expect(described_class::VIPS_AVAILABLE).to be(false)
  end

  it 'does not bundle ruby-vips' do
    expect(Gem.loaded_specs).not_to have_key('ruby-vips')
  end
end
