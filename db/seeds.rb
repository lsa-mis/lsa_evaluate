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

# Seed data for Department
Department.create!([
                     { dept_id: 111_222, name: 'Humanities', dept_description: 'Department of Humanities' },
                     { dept_id: 333_444, name: 'Sciences', dept_description: 'Department of Sciences' }
                   ])

# Seed data for Visibility
Visibility.create!([
                     { kind: 'Public' },
                     { kind: 'Private' }
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
                    { name: 'Freshman', description: 'First year of high school.' },
                    { name: 'Sophomore', description: 'Second year of high school.' },
                    { name: 'Junior', description: 'Third year of high school.' },
                    { name: 'Senior', description: 'Fourth year of high school.' },
                    { name: 'Graduate', description: 'Post-secondary education.' }
                  ])

# Seed data for Users
user1 = User.create!(email: 'alice@example.com', password: 'passwordpassword')
user2 = User.create!(email: 'bob@example.com', password: 'passwordpassword')

# Seed data for Roles
role_admin = Role.create!(kind: 'Admin')
role_user = Role.create!(kind: 'User')

# Seed data for Containers
container1 = Container.create!(
  name: 'Hopwood Contest 2024',
  description: 'The Hopwood Contest for 2024.',
  department: Department.find_by(name: 'Humanities'),
  visibility: Visibility.find_by(kind: 'Public')
  # assignments_attributes: [
  #   { user: user1, role: role_admin },
  #   { user: user2, role: role_user }
  # ],
  # contest_descriptions_attributes: [
  #   contest_description1
  # ]
)

container2 = Container.create!(
  name: 'Science Contest 2024',
  description: 'The Science Contest for 2024.',
  department: Department.find_by(name: 'Sciences'),
  visibility: Visibility.find_by(kind: 'Private')
  #   assignments_attributes: [
  #     { user: user1, role: role_user },
  #     { user: user2, role: role_admin }
  #   ],
  #   contest_descriptions_attributes: [
  #     contest_description2
  #   ]
)

# Seed data for ContestDescription
contest_description1 = ContestDescription.create!(status: Status.find_by(kind: 'Active'), container: container1, name: 'Contest 1', short_name: 'C1', eligibility_rules: 'Rules 1',
                                                  notes: 'Notes 1', created_by: user1.email)
contest_description2 = ContestDescription.create!(status: Status.find_by(kind: 'Archived'), container: container1, name: 'Contest 2', short_name: 'C2', eligibility_rules: 'Rules 2',
                                                  notes: 'Notes 2', created_by: user1.email)

# Seed data for ContestInstance
ContestInstance.create!(
  status: Status.find_by(kind: 'Active'),
  contest_description: contest_description1,
  date_open: DateTime.now - 30,
  date_closed: DateTime.now + 30,
  notes: 'First contest instance',
  judging_open: false,
  judging_rounds: 1,
  category: Category.find_by(kind: 'Drama'),
  has_course_requirement: false,
  judge_evaluations_complete: false,
  course_requirement_description: 'No course requirement',
  recletter_required: false,
  transcript_required: false,
  maximum_number_entries_per_applicant: 1,
  created_by: user1.email
)

ContestInstance.create!(
  status_id: Status.find_by(kind: 'Archived').id,
  contest_description: contest_description2,
  date_open: DateTime.now - 60,
  date_closed: DateTime.now - 30,
  notes: 'Second contest instance',
  judging_open: true,
  judging_rounds: 2,
  category: Category.find_by(kind: 'Fiction'),
  has_course_requirement: true,
  judge_evaluations_complete: true,
  course_requirement_description: 'Course required',
  recletter_required: true,
  transcript_required: true,
  maximum_number_entries_per_applicant: 2,
  created_by: user1.email
)
