# frozen_string_literal: true

if Rails.env.production? && ENV['SKIP_SEEDS'] != 'true'
  puts "\n[WARNING] Attempting to run seeds in production environment!"
  puts "If you really want to do this, set SKIP_SEEDS=false\n\n"
  exit 1
end

unless Rails.env.production? || ENV['SKIP_SEEDS']
  require 'faker'
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
                          { page: 'profiles', section: 'finaid_information',
                            content: ActionText::RichText.new(body: "Financial assistance from all sources during the
                            academic year (September thru August), including prize money earned from Hopwood Award
                            contests, factors into the ongoing review of students financial aid eligibility now and in
                            the future. If your total financial aid, including any new offer, exceeds your eligibility
                            for financial assistance this academic year, your aid may be limited in a future term or
                            reduced from previously received assistance. You can learn more about financial aid terms
                            and conditions on the Office of Financial Aid's website. If you have questions or want to
                            consult with someone about your particular situation, please contact OFA.") },
                          { page: 'profiles', section: 'information',
                            content: ActionText::RichText.new(body: "Be sure keep your profile up to date.") },
                          { page: "containers", section: "instructions",
                            content: ActionText::RichText.new(body: "Instructions for the containers index page") },
                          { page: "container", section: "information",
                            content: ActionText::RichText.new(body: "Information for the container page") },
                          { page: "container", section: "permissions",
                            content: ActionText::RichText.new(body: "Instructions for the container permissions") },
                          { page: "applicant_dashboard", section: "submission_summary",
                            content: ActionText::RichText.new(body: "Instructions for the submission_summary") },
                          { page: "applicant_dashboard", section: "available_contests",
                            content: ActionText::RichText.new(body: "Instructions for the available_contests") },
                          { page: "judge_dashboard", section: "instructions",
                            content: ActionText::RichText.new(body: "Instructions for the judge_dashboard") },
                          { page: "contest_instances", section: "instructions",
                            content: ActionText::RichText.new(body: "Instructions for the contest_instances") },
                          { page: "judging_assignments", section: "instructions",
                            content: ActionText::RichText.new(body: "Instructions for the judging_assignments") },
                          { page: "round_judge_assignments", section: "instructions",
                            content: ActionText::RichText.new(body: "Instructions for the round_judge_assignments") },
                          { page: "judging_assignments", section: "round_specific_instructions",
                            content: ActionText::RichText.new(body: "Instructions for the round_specific_instructions") },
                          { page: "judging_rounds", section: "comment_interface_behavior",
                            content: ActionText::RichText.new(body: "Instructions for the comment_interface_behavior") },
                          { page: "applicant_dashboard", section: "inactivesubmission_summary",
                            content: ActionText::RichText.new(body: "Instructions for the inactivesubmission_summary") },
                          { page: "containers", section: "form_instructions",
                            content: ActionText::RichText.new(body: "Instructions for the form_instructions") }
                        ])

  # Seed data for School
  School.create([
                  { name: 'LSA' },
                  { name: 'Nursing' },
                  { name: 'Business' },
                  { name: 'Engineering' },
                  { name: 'Arts and Sciences' },
                  { name: 'Public Policy' },
                  { name: 'Information' },
                  { name: 'Kinesiology' },
                  { name: 'Law' },
                  { name: 'Art and Design' },
                  { name: 'Education' },
                  { name: 'Other' }
                ])

  # Seed data for Campus
  Campus.create([
                  { campus_descr: 'Ann Arbor', campus_cd: 100 },
                  { campus_descr: 'Flint', campus_cd: 700 },
                  { campus_descr: 'Dearborn', campus_cd: 710 }
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
                    { kind: 'Text-Image', description: 'Category for text-image works.' },
                    { kind: 'Research Paper', description: 'Category for research paper works.' }
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
  user1 = User.create!(email: 'alicefac@example.com',
                      password: 'passwordpassword',
                      uniqname: 'alicefac',
                      uid: 'alicefac',
                      principal_name: 'alicefac@example.com',
                      display_name: 'Alice Wonderland',
                      first_name: 'Alice',
                      last_name: 'Wonderland',
                      affiliations_attributes: [
                                                  { name: 'faculty' },
                                                  { name: 'employee' },
                                                  { name: 'member' }
                                                ]
                      )
  user2 = User.create!(email: 'bobstaff@example.com',
                      password: 'passwordpassword',
                      uniqname: 'bobstaff',
                      uid: 'bobstaff',
                      principal_name: 'bobstaff@example.com',
                      display_name: 'Bob Builder',
                      first_name: 'Bob',
                      last_name: 'Builder',
                      affiliations_attributes: [
                                                  { name: 'staff' },
                                                  { name: 'employee' },
                                                  { name: 'member' }
                                                ]
  )
  user3 = User.create!(email: 'sallystu@example.com',
                      password: 'passwordpassword',
                      uniqname: 'sallystu',
                      uid: 'sallystu',
                      first_name: 'Sally',
                      last_name: 'Student',
                      principal_name: 'sallystu@example.com',
                      display_name: 'Sally Student',
                      affiliations_attributes: [
                                                  { name: 'student' },
                                                  { name: 'member' }
                                                ]
  )
  user4 = User.create!(email: 'rsmoke@umich.edu', password: 'passwordpassword')
  user5 = User.create!(email: 'brita@umich.edu', password: 'passwordpassword')
  user6 = User.create!(email: 'jjsantos@umich.edu', password: 'passwordpassword')
  user7 = User.create!(email: 'mlaitan@umich.edu', password: 'passwordpassword')

  # # Data for new users
  # new_users_data = [
  #   { email: "stufirst@example.com", uniqname: "stufirst", uid: "stufirst", principal_name: "stufirst@example.com", display_name: "Student First" },
  #   { email: "stusecond@example.com", uniqname: "stusecond", uid: "stusecond", principal_name: "stusecond@example.com", display_name: "Student Second" },
  #   { email: "stujunior@example.com", uniqname: "stujunior", uid: "stujunior", principal_name: "stujunior@example.com", display_name: "Student Junior" },
  #   { email: "stusenior@example.com", uniqname: "stusenior", uid: "stusenior", principal_name: "stusenior@example.com", display_name: "Student Senior" },
  #   { email: "stugrad@example.com", uniqname: "stugrad", uid: "stugrad", principal_name: "stugrad@example.com", display_name: "Student Grad" }
  # ]

  # # Shared password
  # password = "passwordpassword"

  # # Shared affiliations
  # affiliations_attributes = [
  #   { name: 'student' },
  #   { name: 'member' }
  # ]

  # # Create new users
  # new_users_data.each do |user_data|
  #   User.create!(
  #     email: user_data[:email],
  #     password: password,
  #     uniqname: user_data[:uniqname],
  #     uid: user_data[:uid],
  #     principal_name: user_data[:principal_name],
  #     display_name: user_data[:display_name],
  #     first_name: user_data[:display_name].split.first, # Extract first name
  #     last_name: user_data[:display_name].split.last,   # Extract last name
  #     affiliations_attributes: affiliations_attributes
  #   )
  # end

  # puts "New users created successfully!"

  # Seed data for Roles
  Role.create!([
                { kind: 'Axis mundi' },
                { kind: 'Collection Administrator' },
                { kind: 'Collection Manager' },
                { kind: 'Judge' }
              ])
  role_container_admin = Role.find_by(kind: 'Collection Administrator')
  axis_mundi = Role.find_by(kind: 'Axis mundi')

  UserRole.create!([
                    { user: user4, role: axis_mundi },
                    { user: user5, role: axis_mundi },
                    { user: user6, role: axis_mundi },
                    { user: user7, role: axis_mundi }
                  ])

  # Seed data for Containers
  container1 = Container.create!(
    name: 'Hopwood Contest Awards',
    description: 'The Hopwood Contest.',
    department: Department.find_by(name: 'LSA English Language & Lit.'),
    visibility: Visibility.find_by(kind: 'Public'),
    creator: user1
  )

  container2 = Container.create!(
    name: 'Science Contest',
    description: 'The Science Contest.',
    department: Department.find_by(name: 'LSA Physics'),
    visibility: Visibility.find_by(kind: 'Private'),
    creator: user2
  )

  # Seed data for ContestDescription
  contest_description1 = ContestDescription.create!(
    active: true,
    container: container1,
    name: 'Cora Duncan Contest',
    short_name: 'Cora Duncan',
    eligibility_rules: 'Rules 1',
    notes: 'Notes 1',
    created_by: user1.email
  )

  contest_description2 = ContestDescription.create!(
    container: container1,
    name: 'Arthur Miller',
    short_name: 'AM',
    eligibility_rules: 'Rules 2',
    notes: 'Notes 2',
    created_by: user1.email
  )

  contest_description3 = ContestDescription.create!(
    active: true,
    container: container2,
    name: 'Physics Sprint Challenge',
    short_name: 'Physics Racers ',
    eligibility_rules: 'Rules 2',
    notes: 'Notes 2',
    created_by: user1.email
  )

  # Seed data for ContestInstance
  contest_instance1 = ContestInstance.create!(
    active: true,
    contest_description: contest_description1,
    date_open: DateTime.now - 30,
    date_closed: DateTime.now + 30,
    notes: 'First contest instance',
    has_course_requirement: false,
    course_requirement_description: 'No course requirement',
    recletter_required: false,
    transcript_required: false,
    require_pen_name: true,
    maximum_number_entries_per_applicant: 1,
    created_by: user1.email,
    class_levels: [ ClassLevel.find_by(name: 'First year') ],
    categories: [ Category.find_by(kind: 'Drama') ]
  )

  # Do the same for the other contest instances
  contest_instance2 = ContestInstance.create!(
    contest_description: contest_description2,
    date_open: DateTime.now - 60,
    date_closed: DateTime.now - 30,
    notes: 'Second contest instance',
    has_course_requirement: false,
    course_requirement_description: 'No course requirement',
    recletter_required: true,
    transcript_required: true,
    require_pen_name: true,
    maximum_number_entries_per_applicant: 2,
    created_by: user1.email,
    class_levels: [ ClassLevel.find_by(name: 'Second year') ],
    categories: [ Category.find_by(kind: 'Fiction') ]
  )

  contest_instance3 = ContestInstance.create!(
    active: true,
    contest_description: contest_description3,
    date_open: DateTime.now - 30,
    date_closed: DateTime.now + 30,
    notes: 'Third contest instance',
    has_course_requirement: false,
    course_requirement_description: 'Course required',
    recletter_required: false,
    transcript_required: true,
    require_pen_name: false,
    maximum_number_entries_per_applicant: 1,
    created_by: user1.email,
    class_levels: [ ClassLevel.find_by(name: 'Second year'), ClassLevel.find_by(name: 'Junior') ],
    categories: [ Category.find_by(kind: 'Research Paper') ]
  )
end
