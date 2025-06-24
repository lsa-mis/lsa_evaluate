require 'rails_helper'

RSpec.describe ContainersHelper, type: :helper do
  let(:container) { create(:container) }
  let(:description) { create(:contest_description, container: container) }

  describe "#render_description" do
    context "when description is longer than 100 characters" do
      let(:long_text) { "This is a very long description that will definitely exceed the 100 character limit and therefore trigger the modal functionality." }
      let(:rich_text) { instance_double(ActionText::RichText, to_plain_text: long_text) }

      before do
        allow(container).to receive(:description)
          .and_return(rich_text)
      end

      it "returns truncated text with modal link" do
        result = helper.render_description(container)
        parsed_result = Nokogiri::HTML.fragment(result.to_s)
        link = parsed_result.at_css('a')

        # Check link attributes
        expect(link['data-action']).to eq('click->modal#open')
        expect(link['data-modal-title']).to eq('Description')
        expect(link['href']).to eq('#')
        expect(link.text).to eq('...more')

        # Check truncated text
        expect(parsed_result.text).to include(long_text[0..99])
      end
    end

    context "when description is shorter than 100 characters" do
      let(:short_text) { "Short description" }
      let(:rich_text) { instance_double(ActionText::RichText, to_plain_text: short_text) }

      before do
        allow(container).to receive(:description)
          .and_return(rich_text)
      end

      it "returns the full description without modal link" do
        result = helper.render_description(container)
        expect(result).to eq(rich_text)
        expect(result.to_s).not_to include('...more')
      end
    end
  end

  describe "#render_eligibility_rules" do
    context "when eligibility rules are longer than 60 characters" do
      let(:long_text) { "These are very long eligibility rules that will definitely exceed the 60 character limit and therefore trigger the modal functionality." }
      let(:rich_text) { instance_double(ActionText::RichText, to_plain_text: long_text) }

      before do
        allow(description).to receive(:eligibility_rules)
          .and_return(rich_text)
      end

      it "returns truncated text with modal link" do
        result = helper.render_eligibility_rules(description)
        parsed_result = Nokogiri::HTML.fragment(result.to_s)
        link = parsed_result.at_css('a')

        # Check link attributes
        expect(link['data-action']).to eq('click->modal#open')
        expect(link['data-modal-title']).to eq('Eligibility Rules')
        expect(link['href']).to eq('#')
        expect(link.text).to eq(' ...more')

        # Check truncated text
        expect(parsed_result.text).to include(long_text[0..59])
      end
    end

    context "when eligibility rules are shorter than 100 characters" do
      let(:short_text) { "Short rules" }
      let(:rich_text) { instance_double(ActionText::RichText, to_plain_text: short_text) }

      before do
        allow(description).to receive(:eligibility_rules)
          .and_return(rich_text)
      end

      it "returns the full eligibility rules without modal link" do
        result = helper.render_eligibility_rules(description)
        expect(result).to eq(rich_text)
        expect(result.to_s).not_to include('...more')
      end
    end
  end
end
