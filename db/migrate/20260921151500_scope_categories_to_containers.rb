# frozen_string_literal: true

class ScopeCategoriesToContainers < ActiveRecord::Migration[8.1]
  class MigrationCategory < ApplicationRecord
    self.table_name = 'categories'
  end

  class MigrationCategoryContestInstance < ApplicationRecord
    self.table_name = 'category_contest_instances'
  end

  class MigrationEntry < ApplicationRecord
    self.table_name = 'entries'
  end

  class MigrationContestInstance < ApplicationRecord
    self.table_name = 'contest_instances'
  end

  class MigrationContestDescription < ApplicationRecord
    self.table_name = 'contest_descriptions'
  end

  class MigrationContainer < ApplicationRecord
    self.table_name = 'containers'
  end

  def up
    # MySQL DDL implicitly commits, so validate ownership before any schema change.
    # Otherwise a mid-migration raise leaves a half-migrated, non-retryable schema.
    scope_plan = build_category_scope_plan!

    add_reference :categories, :container, null: true, foreign_key: true
    remove_index :categories, name: 'index_categories_on_kind'

    say_with_time 'Scoping categories to containers' do
      MigrationCategory.reset_column_information

      scope_plan.each do |category_id, container_ids|
        category = MigrationCategory.find(category_id)
        primary_container_id = container_ids.first
        category.update_columns(container_id: primary_container_id)

        container_ids.drop(1).each do |container_id|
          duplicate = MigrationCategory.create!(
            kind: category.kind,
            description: category.description,
            container_id: container_id,
            created_at: category.created_at,
            updated_at: Time.current
          )
          remap_category_for_container!(category.id, duplicate.id, container_id)
        end
      end
    end

    remaining = MigrationCategory.where(container_id: nil)
    if remaining.exists?
      raise "Unable to assign containers to categories: #{remaining.pluck(:id, :kind).inspect}"
    end

    change_column_null :categories, :container_id, false
    add_index :categories, [ :container_id, :kind ],
              unique: true,
              name: 'index_categories_on_container_id_and_kind'
  end

  def down
    # up may duplicate kind across containers; restoring a global unique kind index
    # cannot safely reverse that without remapping and merging rows.
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def build_category_scope_plan!
    plan = {}
    unmapped = []

    MigrationCategory.find_each do |category|
      container_ids = container_ids_for(category)
      if container_ids.empty?
        unmapped << category
      else
        plan[category.id] = container_ids
      end
    end

    return plan if unmapped.empty?

    details = unmapped.map { |category| "##{category.id} (#{category.kind})" }.join(', ')
    raise 'Cannot scope categories to containers: these categories have no ' \
          "contest-instance or entry references to determine ownership: #{details}. " \
          'Assign them to a contest or remove them before migrating.'
  end

  def container_ids_for(category)
    via_instances = MigrationCategoryContestInstance
      .joins('INNER JOIN contest_instances ON contest_instances.id = category_contest_instances.contest_instance_id')
      .joins('INNER JOIN contest_descriptions ON contest_descriptions.id = contest_instances.contest_description_id')
      .where(category_id: category.id)
      .distinct
      .pluck('contest_descriptions.container_id')

    via_entries = MigrationEntry
      .joins('INNER JOIN contest_instances ON contest_instances.id = entries.contest_instance_id')
      .joins('INNER JOIN contest_descriptions ON contest_descriptions.id = contest_instances.contest_description_id')
      .where(category_id: category.id)
      .distinct
      .pluck('contest_descriptions.container_id')

    (via_instances + via_entries).compact.uniq.sort
  end

  def remap_category_for_container!(old_category_id, new_category_id, container_id)
    instance_ids = MigrationContestInstance
      .joins('INNER JOIN contest_descriptions ON contest_descriptions.id = contest_instances.contest_description_id')
      .where('contest_descriptions.container_id = ?', container_id)
      .pluck(:id)

    return if instance_ids.empty?

    MigrationCategoryContestInstance
      .where(category_id: old_category_id, contest_instance_id: instance_ids)
      .update_all(category_id: new_category_id)

    MigrationEntry
      .where(category_id: old_category_id, contest_instance_id: instance_ids)
      .update_all(category_id: new_category_id)
  end
end
