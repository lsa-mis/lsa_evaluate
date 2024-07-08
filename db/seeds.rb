# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
EditableContent.create([
                         { page: 'home', section: 'instructions', content: ActionText::RichText.new(body: 'Lorem ipsum dolor sit amet, vince adipiscing elit,
                          sed do eiusmod tempor incididunt ut labore et dolore
                          magna aliqua. Ut enim ad minim veniam, quis nostrud
                          exercitation ullamco laboris nisi ut aliquip ex ea
                          commodo consequat. Duis aute irure dolor in reprehenderit
                          in voluptate velit esse cillum dolore eu fugiat nulla pariatur.') },
                         { page: 'home', section: 'description', content: 'Short paragraph explaining LSA Evaluate.' }
                       ])

Status.create([
                { kind: 'Active', description: 'The entity is active and operational.' },
                { kind: 'Deleted', description: 'The entity has been deleted.' },
                { kind: 'Archived', description: 'The entity is archived.' },
                { kind: 'Disqualified', description: 'The entity is disqualified.' }
              ])

Category.create([
                  { kind: 'Drama', description: 'Category for drama works.' },
                  { kind: 'Screenplay', description: 'Category for screenplay works.' },
                  { kind: 'Non-Fiction', description: 'Category for non-fiction works.' },
                  { kind: 'Fiction', description: 'Category for fiction works.' },
                  { kind: 'Poetry', description: 'Category for poetry works.' },
                  { kind: 'Novel', description: 'Category for novel works.' },
                  { kind: 'Short Fiction', description: 'Category for short fiction works.' },
                  { kind: 'Text-Image', description: 'Category for text-image works.' }
                ])

ClassLevel.create([
                    { level: 'Freshman', description: 'First year of high school.' },
                    { level: 'Sophomore', description: 'Second year of high school.' },
                    { level: 'Junior', description: 'Third year of high school.' },
                    { level: 'Senior', description: 'Fourth year of high school.' },
                    { level: 'Graduate', description: 'Post-secondary education.' }
                  ])

# Seed data for Status
status_active = Status.find_by(kind: 'Active')
status_archived = Status.find_by(kind: 'Archived')

# Seed data for ContestDescription
contest_description1 = ContestDescription.create!(name: 'Contest 1', short_name: 'C1', eligibility_rules: 'Rules 1',
                                                  notes: 'Notes 1', created_by: 'Admin')
contest_description2 = ContestDescription.create!(name: 'Contest 2', short_name: 'C2', eligibility_rules: 'Rules 2',
                                                  notes: 'Notes 2', created_by: 'Admin')

# Seed data for Category
category_drama = Category.find_by(kind: 'Drama')
category_fiction = Category.find_by(kind: 'Fiction')

# Seed data for ContestInstance
ContestInstance.create!(
  status: status_active,
  contest_description: contest_description1,
  date_open: DateTime.now - 30,
  date_closed: DateTime.now + 30,
  notes: 'First contest instance',
  judging_open: false,
  judging_rounds: 1,
  category: category_drama,
  has_course_requirement: false,
  judge_evaluations_complete: false,
  course_requirement_description: 'No course requirement',
  recletter_required: false,
  transcript_required: false,
  maximum_number_entries_per_applicant: 1,
  created_by: 'Admin'
)

ContestInstance.create!(
  status: status_archived,
  contest_description: contest_description2,
  date_open: DateTime.now - 60,
  date_closed: DateTime.now - 30,
  notes: 'Second contest instance',
  judging_open: true,
  judging_rounds: 2,
  category: category_fiction,
  has_course_requirement: true,
  judge_evaluations_complete: true,
  course_requirement_description: 'Course required',
  recletter_required: true,
  transcript_required: true,
  maximum_number_entries_per_applicant: 2,
  created_by: 'Admin'
)
