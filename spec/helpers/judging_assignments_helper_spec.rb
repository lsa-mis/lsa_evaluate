require 'rails_helper'

RSpec.describe JudgingAssignmentsHelper, type: :helper do
  describe '#display_email' do
    context 'with transformed umich email' do
      it 'converts username+gmail.com@umich.edu to username@gmail.com' do
        expect(helper.display_email('judge+gmail.com@umich.edu')).to eq('judge@gmail.com')
      end

      it 'converts username+yahoo.com@umich.edu to username@yahoo.com' do
        expect(helper.display_email('judge+yahoo.com@umich.edu')).to eq('judge@yahoo.com')
      end

      it 'handles complex usernames' do
        expect(helper.display_email('john.doe+gmail.com@umich.edu')).to eq('john.doe@gmail.com')
      end
    end

    context 'with regular emails' do
      it 'keeps regular umich.edu email unchanged' do
        expect(helper.display_email('judge@umich.edu')).to eq('judge@umich.edu')
      end

      it 'keeps non-umich email unchanged' do
        expect(helper.display_email('judge@gmail.com')).to eq('judge@gmail.com')
      end
    end
  end
end
