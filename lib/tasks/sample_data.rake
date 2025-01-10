namespace :sample_data do
  desc 'Create sample contest entries for testing'
  task create_entries: :environment do
    # Find or create required records
    contest_description = ContestDescription.first || ContestDescription.create!(
      name: 'Sample Contest 2024',
      created_by: 'system',
      container: Container.first || Container.create!(
        name: 'Sample Container',
        department: Department.first || Department.create!(name: 'Sample Department'),
        visibility: Visibility.first || Visibility.create!(kind: 'Public')
      )
    )

    contest_instance = ContestInstance.first ||
      ContestInstance.create!(
        contest_description: contest_description,
        description: 'A sample contest for testing',
        date_open: Date.today,
        date_closed: 1.month.from_now,
        require_pen_name: true,
        created_by: 'system'
      )

    category = Category.first || Category.create!(kind: 'Poetry', description: 'Poetry submissions')

    # Create required reference data if not exists
    class_level = ClassLevel.first || ClassLevel.create!(name: 'Senior', description: 'Fourth year student')
    school = School.first || School.create!(name: 'Literature, Science, and the Arts')
    campus = Campus.first || Campus.create!(campus_descr: 'Ann Arbor', campus_cd: 1)

    # Create address types if they don't exist
    home_type = AddressType.find_or_create_by!(kind: 'Home', description: 'Home address')
    campus_type = AddressType.find_or_create_by!(kind: 'Campus', description: 'Campus address')

    # Sample titles for creative writing entries
    titles = [
      'The Last Sunset',
      'Whispers in the Wind',
      'Beyond the Horizon',
      'Echoes of Tomorrow',
      'The Silent Garden',
      'Memories of Rain',
      'The Forgotten Door',
      'Dancing Shadows',
      'The Crystal Key',
      "Autumn's Secret",
      'The Time Keeper',
      "Midnight's Promise",
      'The Paper Boat',
      "Winter's Song"
    ]

    # Create entries
    titles.each_with_index do |title, index|
      # Create addresses
      home_address = Address.create!(
        address_type: home_type,
        address1: "#{1000 + index} Home St",
        city: 'Ann Arbor',
        state: 'MI',
        zip: '48109',
        country: 'USA'
      )

      campus_address = Address.create!(
        address_type: campus_type,
        address1: "#{2000 + index} Campus Dr",
        city: 'Ann Arbor',
        state: 'MI',
        zip: '48109',
        country: 'USA'
      )

      # Create a user for each entry
      user = User.find_or_create_by!(email: "author#{index + 1}@example.com") do |u|
        u.first_name = 'Author'
        u.last_name = "#{index + 1}"
        u.password = 'ThisIsALongPassword123!@#'
        u.password_confirmation = 'ThisIsALongPassword123!@#'
      end

      # Create a profile for the user
      profile = Profile.find_or_create_by!(user: user) do |p|
        p.preferred_first_name = user.first_name
        p.preferred_last_name = user.last_name
        p.grad_date = Date.new(2024, 5, 1)
        p.degree = 'BA'
        p.umid = format('%08d', index + 10000000)  # 8-digit UMID
        p.class_level = class_level
        p.campus = campus
        p.school = school
        p.major = 'Creative Writing'
        p.home_address = home_address
        p.campus_address = campus_address
      end

      Entry.find_or_create_by!(title: title) do |entry|
        entry.contest_instance = contest_instance
        entry.profile = profile
        entry.category = category
        entry.pen_name = "Poet#{index + 1}"
        entry.created_at = Time.current - rand(1..30).days

        # Create a temporary markdown file
        temp_file = Tempfile.new([ 'entry', '.md' ])
        temp_file.write("# #{title}\n\n")
        temp_file.write("## By #{entry.pen_name}\n\n")
        temp_file.write("This is a sample entry for testing purposes.\n\n")
        temp_file.write('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.')
        temp_file.rewind

        # Convert to PDF using pandoc
        pdf_file = Tempfile.new([ 'entry', '.pdf' ])
        system("pandoc #{temp_file.path} -o #{pdf_file.path}")

        # Attach the PDF file to the entry
        entry.entry_file.attach(
          io: File.open(pdf_file.path),
          filename: "#{title.downcase.gsub(/[^a-z0-9]/, '_')}.pdf",
          content_type: 'application/pdf'
        )

        temp_file.close
        temp_file.unlink
        pdf_file.close
        pdf_file.unlink

        puts "Created entry: #{title} by #{profile.preferred_first_name} #{profile.preferred_last_name} (#{entry.pen_name})"
      end
    end

    puts "\nCreated #{titles.length} sample entries for contest: #{contest_instance.contest_description.name}"
  end
end
