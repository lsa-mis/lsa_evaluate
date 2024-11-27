# == Schema Information
#
# Table name: user_roles
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  role_id    :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_roles_on_role_id              (role_id)
#  index_user_roles_on_user_id              (user_id)
#  index_user_roles_on_user_id_and_role_id  (user_id,role_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (role_id => roles.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe UserRole, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it 'belongs to role' do
      association = described_class.reflect_on_association(:role)
      expect(association.macro).to eq :belongs_to
    end
  end

  describe 'validations' do
    it 'validates uniqueness of role_id scoped to user_id' do
      user = User.create!(email: 'testuser@example.com', encrypted_password: 'passwordpassword',
                          password: 'passwordpassword')
      role = Role.create!(kind: 'Test Role')
      UserRole.create!(user:, role:)

      duplicate_user_role = UserRole.new(user:, role:)
      expect(duplicate_user_role).not_to be_valid
      expect(duplicate_user_role.errors[:role_id]).to include('role already assigned to user')
    end
  end

  describe 'schema' do
    it 'has the correct columns' do
      columns = UserRole.column_names
      expect(columns).to include('id')
      expect(columns).to include('created_at')
      expect(columns).to include('updated_at')
      expect(columns).to include('role_id')
      expect(columns).to include('user_id')
    end
  end

  describe 'indexes' do
    it 'has an index on role_id' do
      expect(ActiveRecord::Base.connection.index_exists?(:user_roles, :role_id)).to be true
    end

    it 'has an index on user_id' do
      expect(ActiveRecord::Base.connection.index_exists?(:user_roles, :user_id)).to be true
    end

    it 'has a unique index on user_id and role_id' do
      expect(ActiveRecord::Base.connection.index_exists?(:user_roles, %i[user_id role_id], unique: true)).to be true
    end
  end

  describe 'foreign keys' do
    it 'has a foreign key on role_id' do
      expect(UserRole.connection.foreign_keys('user_roles').any? { |fk| fk.column == 'role_id' }).to be true
    end

    it 'has a foreign key on user_id' do
      expect(UserRole.connection.foreign_keys('user_roles').any? { |fk| fk.column == 'user_id' }).to be true
    end
  end
end
