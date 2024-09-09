# == Schema Information
#
# Table name: containers
#
#  id            :bigint           not null, primary key
#  description   :text(65535)
#  name          :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  department_id :bigint           not null
#  visibility_id :bigint           not null
#
# Indexes
#
#  index_containers_on_department_id  (department_id)
#  index_containers_on_visibility_id  (visibility_id)
#
# Foreign Keys
#
#  fk_rails_...  (department_id => departments.id)
#  fk_rails_...  (visibility_id => visibilities.id)
#
require 'rails_helper'

RSpec.describe Container do
  describe 'associations' do
    it 'belongs to department' do
      association = described_class.reflect_on_association(:department)
      expect(association.macro).to eq :belongs_to
    end

    it 'belongs to visibility' do
      association = described_class.reflect_on_association(:visibility)
      expect(association.macro).to eq :belongs_to
    end

    it 'has many assignments with dependent destroy' do
      association = described_class.reflect_on_association(:assignments)
      expect(association.macro).to eq :has_many
      expect(association.options[:dependent]).to eq :destroy
    end

    it 'has many users through assignments' do
      association = described_class.reflect_on_association(:users)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :assignments
    end

    it 'has many roles through assignments' do
      association = described_class.reflect_on_association(:roles)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :assignments
    end

    it 'has many contest_descriptions with dependent destroy' do
      association = described_class.reflect_on_association(:contest_descriptions)
      expect(association.macro).to eq :has_many
      expect(association.options[:dependent]).to eq :destroy
    end
  end

  describe 'nested attributes' do
    it 'accepts nested attributes for assignments with allow destroy' do
      expect(Container.nested_attributes_options[:assignments][:allow_destroy]).to be true
    end

    it 'accepts nested attributes for contest_descriptions with allow destroy' do
      expect(Container.nested_attributes_options[:contest_descriptions][:allow_destroy]).to be true
    end
  end

  describe 'validations' do
    it 'validates presence of name' do
      container = Container.new(name: nil)
      container.validate
      expect(container).not_to be_valid
    end

    it 'validates presence of department_id' do
      container = Container.new(department_id: nil)
      container.validate
      expect(container).not_to be_valid
    end

    it 'validates presence of visibility_id' do
      container = Container.new(visibility_id: nil)
      container.validate
      expect(container).not_to be_valid
    end

    context 'when the container is created' do
      let(:user) { create(:user, :employee) }
      let(:department) { create(:department) }
      let(:visibility) { create(:visibility) }
      let!(:container_admin_role) { create(:role, kind: 'Container Administrator') }

      before do
        # Pass the current_user to the container using the `creator` attribute
        @container = Container.new(
          name: 'Test Container',
          department:,
          visibility:,
          creator: user
        )
      end

      it 'creates an assignment for the creator as Container Administrator when the container is created' do
        expect { @container.save! }.to change { Assignment.count }.by(1)
        assignment = Assignment.find_by(container: @container, user:, role: container_admin_role)
        expect(assignment).to be_present
      end
    end
  end

  describe 'indexes' do
    it 'has index on department_id' do
      expect(ActiveRecord::Base.connection.index_exists?(:containers, :department_id)).to be true
    end

    it 'has index on visibility_id' do
      expect(ActiveRecord::Base.connection.index_exists?(:containers, :visibility_id)).to be true
    end
  end

  describe 'foreign keys' do
    it 'has foreign key on department_id' do
      expect(Container.connection.foreign_keys('containers').any? { |fk| fk.column == 'department_id' }).to be true
    end

    it 'has foreign key on visibility_id' do
      expect(Container.connection.foreign_keys('containers').any? { |fk| fk.column == 'visibility_id' }).to be true
    end
  end
end
