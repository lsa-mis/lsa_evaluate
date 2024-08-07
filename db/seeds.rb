# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Seed data for EditableContent
EditableContent.create([
                         { page: 'home', section: 'instructions',
                           content: ActionText::RichText.new(body: 'Lorem ipsum dolor sit amet, vince adipiscing elit,
                           sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
                           quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis
                           aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
                           pariatur.') },
                         { page: 'home', section: 'description',
                           content: ActionText::RichText.new(body: 'Short paragraph explaining LSA Evaluate.') },
                         { page: 'home', section: 'submit_entry',
                           content: ActionText::RichText.new(body: 'Information on the submit_entry section.
                           Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod  tempor incididunt
                           ut labore et dolore magna aliqua. Ut enim ad minim  veniam, quis nostrud exercitation
                           ullamco laboris nisi ut aliquip ex ea  commodo consequat.') },
                         { page: 'home', section: 'manage_submissions',
                           content: ActionText::RichText.new(body: 'Information on the manage_submissions section.
                           Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod  tempor incididunt
                           ut labore et dolore magna aliqua. Ut enim ad minim  veniam, quis nostrud exercitation
                           ullamco laboris nisi ut aliquip ex ea  commodo consequat.') },
                         { page: 'home', section: 'view_submissions',
                           content: ActionText::RichText.new(body: 'Information on the view_submissions section.
                           Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod  tempor incididunt
                           ut labore et dolore magna aliqua. Ut enim ad minim  veniam, quis nostrud exercitation
                           ullamco laboris nisi ut aliquip ex ea  commodo consequat.') },
                         { page: 'home', section: 'manage_profile',
                           content: ActionText::RichText.new(body: 'Information on the manage_profile section.
                           Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod  tempor incididunt
                           ut labore et dolore magna aliqua. Ut enim ad minim  veniam, quis nostrud exercitation
                           ullamco laboris nisi ut aliquip ex ea  commodo consequat.') },
                         { page: 'profiles', section: 'finaid_information',
                           content: ActionText::RichText.new(body: "Financial assistance from all sources during the
                           academic year (September thru August), including prize money earned from Hopwood Award
                           contests, factors into the ongoing review of students financial aid eligibility now and in
                           the future. If your total financial aid, including any new offer, exceeds your eligibility
                           for financial assistance this academic year, your aid may be limited in a future term or
                           reduced from previously received assistance. You can learn more about financial aid terms
                           and conditions on the Office of Financial Aid's website. If you have questions or want to
                           consult with someone about your particular situation, please contact OFA.") }
                       ])

# Seed data for School
School.create([
                { name: 'LSA' },
                { name: 'School of Nursing' },
                { name: 'Ross Business School' },
                { name: 'College of Engineering' },
                { name: 'Rackham' }
              ])

AddressType.create([
                     { kind: 'Home', description: 'Home address' },
                     { kind: 'Campus', description: 'Campus address' }
                   ])

# Create Addresses
Address.create([
                 {
                   address1: Faker::Address.street_address,
                   address2: Faker::Address.secondary_address,
                   city: Faker::Address.city,
                   state: Faker::Address.state_abbr,
                   zip: Faker::Address.zip_code,
                   phone: Faker::PhoneNumber.phone_number,
                   country: Faker::Address.country_code,
                   address_type: AddressType.find_by(kind: 'Home')
                 },
                 {
                   address1: Faker::Address.street_address,
                   address2: Faker::Address.secondary_address,
                   city: Faker::Address.city,
                   state: Faker::Address.state_abbr,
                   zip: Faker::Address.zip_code,
                   phone: Faker::PhoneNumber.phone_number,
                   country: Faker::Address.country_code,
                   address_type: AddressType.find_by(kind: 'Campus')
                 },
                 {
                   address1: Faker::Address.street_address,
                   address2: Faker::Address.secondary_address,
                   city: Faker::Address.city,
                   state: Faker::Address.state_abbr,
                   zip: Faker::Address.zip_code,
                   phone: Faker::PhoneNumber.phone_number,
                   country: Faker::Address.country_code,
                   address_type: AddressType.find_by(kind: 'Home')
                 }
               ])

# Seed data for Campus
Campus.create([
                { campus_descr: 'AnnArbor', campus_cd: 1001 },
                { campus_descr: 'Flint', campus_cd: 1002 },
                { campus_descr: 'Dearborn', campus_cd: 1003 }
              ])

# Seed data for Status
Status.create([
                { kind: 'Active', description: 'The entity is active and operational.' },
                { kind: 'Deleted', description: 'The entity has been deleted.' },
                { kind: 'Archived', description: 'The entity is archived.' },
                { kind: 'Disqualified', description: 'The entity is disqualified.' }
              ])

# Seed data for Department
Department.create([
                    { dept_id: 179_000, name: 'LSA History', dept_description: 'Department of History' },
                    { dept_id: 184_500, name: 'LSA Physics', dept_description: 'Department of Physics' },
                    { dept_id: 175_500, name: 'LSA English Language & Lit.', dept_description: 'ELL' }
                  ])

# Seed data for Visibility
Visibility.create([
                    { kind: 'Public' },
                    { kind: 'Private' }
                  ])

# Seed data for Category
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

# Seed data for ClassLevel
ClassLevel.create([
                    { name: 'First year', description: 'First year of school.' },
                    { name: 'Second year', description: 'Second year of school.' },
                    { name: 'Junior', description: 'Third year of school.' },
                    { name: 'Senior', description: 'Fourth year of school.' },
                    { name: 'Graduate', description: 'Post-secondary education.' }
                  ])

# Seed data for Users
user1 = User.create!(email: 'alice@example.com', password: 'passwordpassword')
user2 = User.create!(email: 'bob@example.com', password: 'passwordpassword')
user3 = User.create!(email: 'rsmoke@umich.edu', password: 'passwordpassword')

# Seed data for Roles
Role.create!([
               { kind: 'Container Administrator' },
               { kind: 'Axis mundi' },
               { kind: 'Container Manager' }
             ])
role_admin = Role.find_by(kind: 'Container Administrator')
axis_mundi = Role.find_by(kind: 'Axis mundi')
# role_user = Role.create!(kind: 'User')
UserRole.create!([
                   { user: user3, role: axis_mundi }
                 ])

# Seed data for Containers
container1 = Container.create!(
  name: 'Hopwood Contests',
  description: 'The Hopwood Contest.',
  department: Department.find_by(name: 'LSA English Language & Lit.'),
  visibility: Visibility.find_by(kind: 'Public')
)

container2 = Container.create!(
  name: 'Science Contest',
  description: 'The Science Contest.',
  department: Department.find_by(name: 'LSA Physics'),
  visibility: Visibility.find_by(kind: 'Private')
)

# Seed data for ContestDescription
contest_description1 = ContestDescription.create!(
  status: Status.find_by(kind: 'Active'),
  container: container1,
  name: 'Cora Duncan Contest',
  short_name: 'Cora D',
  eligibility_rules: 'Rules 1',
  notes: 'Notes 1',
  created_by: user1.email
)

contest_description2 = ContestDescription.create!(
  status: Status.find_by(kind: 'Archived'),
  container: container1,
  name: 'Arthur Miller',
  short_name: 'AM',
  eligibility_rules: 'Rules 2',
  notes: 'Notes 2',
  created_by: user1.email
)

contest_description3 = ContestDescription.create!(
  status: Status.find_by(kind: 'Active'),
  container: container2,
  name: 'Physics Sprint Challenge',
  short_name: 'Physics Racers ',
  eligibility_rules: 'Rules 2',
  notes: 'Notes 2',
  created_by: user1.email
)
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
  status: Status.find_by(kind: 'Archived'),
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

# Seed data for Assignments
Assignment.create!([
                     { user: user1, container: container1, role: role_admin },
                     # { user: user2, container: container1, role: role_user },
                     # { user: user1, container: container2, role: role_user },
                     { user: user2, container: container2, role: role_admin }
                   ])
