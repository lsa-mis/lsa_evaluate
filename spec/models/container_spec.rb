# == Schema Information
#
# Table name: containers
#
#  id            :bigint           not null, primary key
#  contact_email :string(255)
#  name          :string(255)
#  notes         :text(65535)
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
      expect(association.options[:dependent]).to eq :restrict_with_error
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
      let!(:container_admin_role) { create(:role, kind: 'Collection Administrator') }

      before do
        # Pass the current_user to the container using the `creator` attribute
        @container = Container.new(
          name: 'Test Container',
          department:,
          visibility:,
          creator: user
        )
      end

      it 'creates an assignment for the creator as Collection Administrator when the collection is created' do
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

  describe '#entries_summary' do
    let(:container) { create(:container) }
    let(:campus1) { create(:campus, campus_descr: 'Campus A') }
    let(:campus2) { create(:campus, campus_descr: 'Campus B') }

    before do
      # Setup test data
      contest_desc = create(:contest_description, container: container, active: true)
      contest_instance = create(:contest_instance, contest_description: contest_desc, active: true)

      # Create profiles with different campuses
      profile1 = create(:profile, campus: campus1)
      profile2 = create(:profile, campus: campus2)

      # Create entries
      create_list(:entry, 2, profile: profile1, contest_instance: contest_instance)
      create(:entry, profile: profile2, contest_instance: contest_instance)
    end

    it 'returns correct entry counts grouped by campus' do
      summary = container.entries_summary

      expect(summary.length).to eq(2)
      expect(summary.find { |s| s.campus_descr == 'Campus A' }.entry_count).to eq(2)
      expect(summary.find { |s| s.campus_descr == 'Campus B' }.entry_count).to eq(1)
    end

    it 'excludes entries from archived contest instances' do
      contest_desc = create(:contest_description, container: container, active: true)
      archived_instance = create(:contest_instance, contest_description: contest_desc, active: true, archived: true)
      create(:entry, profile: create(:profile, campus: campus1), contest_instance: archived_instance)

      summary = container.entries_summary
      expect(summary.find { |s| s.campus_descr == 'Campus A' }.entry_count).to eq(2)
    end

    it 'excludes entries from inactive contest descriptions' do
      inactive_desc = create(:contest_description, container: container, active: false)
      inactive_instance = create(:contest_instance, contest_description: inactive_desc, active: true)
      create(:entry, profile: create(:profile, campus: campus1), contest_instance: inactive_instance)

      summary = container.entries_summary
      expect(summary.find { |s| s.campus_descr == 'Campus A' }.entry_count).to eq(2)
    end
  end

  describe '#total_active_entries' do
    let(:container) { create(:container) }

    it 'returns correct total of active entries' do
      contest_desc = create(:contest_description, container: container, active: true)
      contest_instance = create(:contest_instance, contest_description: contest_desc, active: true)
      create_list(:entry, 3, contest_instance: contest_instance)

      expect(container.total_active_entries).to eq(3)
    end

    it 'excludes deleted entries from count' do
      contest_desc = create(:contest_description, container: container, active: true)
      contest_instance = create(:contest_instance, contest_description: contest_desc, active: true)
      create_list(:entry, 2, contest_instance: contest_instance)
      create(:entry, contest_instance: contest_instance, deleted: true)

      expect(container.total_active_entries).to eq(2)
    end
  end
end
