namespace :sample_data do
  desc 'Create sample data for development'
  task create: :environment do
    # Create roles if they don't exist
    axis_mundi_role = Role.find_or_create_by!(kind: 'Axis Mundi', description: 'Administrator role')
    collection_admin_role = Role.find_or_create_by!(kind: 'Collection Administrator', description: 'Collection administrator role')

    # Create campuses if they don't exist
    ann_arbor_campus = Campus.find_or_create_by!(name: 'Ann Arbor', description: 'Ann Arbor campus')
    dearborn_campus = Campus.find_or_create_by!(name: 'Dearborn', description: 'Dearborn campus')
    flint_campus = Campus.find_or_create_by!(name: 'Flint', description: 'Flint campus')

    # Create schools if they don't exist
    lsa = School.find_or_create_by!(name: 'LSA', description: 'College of Literature, Science, and the Arts')
    engineering = School.find_or_create_by!(name: 'Engineering', description: 'College of Engineering')
    business = School.find_or_create_by!(name: 'Business', description: 'Ross School of Business')

    # Create class levels if they don't exist
    freshman = ClassLevel.find_or_create_by!(name: 'Freshman', description: 'First year student')
    sophomore = ClassLevel.find_or_create_by!(name: 'Sophomore', description: 'Second year student')
    junior = ClassLevel.find_or_create_by!(name: 'Junior', description: 'Third year student')
    senior = ClassLevel.find_or_create_by!(name: 'Senior', description: 'Fourth year student')

    # Create sample users with profiles
    5.times do |index|
      # Create user
      user = User.create!(
        email: "user#{index + 1}@example.com",
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        uniqname: "user#{index + 1}",
        uid: "user#{index + 1}",
        display_name: "User #{index + 1}",
        password: 'passwordpassword',
        affiliations_attributes: [
          { name: 'student' },
          { name: 'member' }
        ]
      )

      # Create profile
      p = Profile.create!(
        user: user,
        preferred_first_name: user.first_name,
        preferred_last_name: user.last_name,
        umid: format('%08d', rand(10000000..99999999)),
        class_level: [freshman, sophomore, junior, senior].sample,
        school: [lsa, engineering, business].sample,
        campus: [ann_arbor_campus, dearborn_campus, flint_campus].sample,
        major: Faker::Educator.subject,
        department: Faker::Educator.subject,
        grad_date: Date.today + rand(1..4).years,
        degree: ['Bachelor\'s', 'Master\'s', 'PhD'].sample,
        receiving_financial_aid: [true, false].sample,
        accepted_financial_aid_notice: true,
        campus_employee: [true, false].sample,
        financial_aid_description: Faker::Lorem.paragraph,
        hometown_publication: Faker::Address.city,
        pen_name: Faker::Book.author
      )

      # Assign roles to some users
      if index < 2
        UserRole.create!(user: user, role: axis_mundi_role)
      elsif index < 4
        UserRole.create!(user: user, role: collection_admin_role)
      end
    end

    puts 'Sample data created successfully!'
  end
end
