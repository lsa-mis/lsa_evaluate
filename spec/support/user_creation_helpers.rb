module UserCreationHelpers
  # Ugrad student can be [student, member, employee]
  def create_ugrad_student_with_profile(class_level_name)
    # Ensure class level exists
    class_level = ClassLevel.find_or_create_by!(
      name: class_level_name,
      description: "#{class_level_name} student"
    )

    user = create(:user,
      email: "student_#{class_level_name.downcase.gsub(' ', '_')}@example.com",
      first_name: "Student",
      last_name: class_level_name,
      password: 'passwordpassword',
      uniqname: "stu#{class_level_name.downcase.gsub(' ', '')}",
      uid: "stu#{class_level_name.downcase.gsub(' ', '')}",
      display_name: "Student #{class_level_name}",
      affiliations_attributes: [
        { name: 'student' },
        { name: 'member' }
      ]
    )

    create(:profile,
      user: user,
      preferred_first_name: user.first_name,
      preferred_last_name: user.last_name,
      class_level: class_level,
      school: create(:school),
      campus: create(:campus),
      grad_date: Date.today + 1.year,
      degree: "Bachelor's",
      umid: format('%08d', rand(10000000..99999999)),
      home_address: create(:address, address_type: create(:address_type, :home)),
      campus_address: create(:address, address_type: create(:address_type, :campus))
    )

    user
  end

  # Grad student can be [staff, student, member, alum, employee, affiliate]
  def create_gradstudent_with_profile(class_level_name)
    user = create(:user,
      email: "student_#{class_level_name.downcase.gsub(' ', '_')}@example.com",
      first_name: "Student",
      last_name: class_level_name,
      uniqname: "stu#{class_level_name.downcase.gsub(' ', '')}",
      uid: "stu#{class_level_name.downcase.gsub(' ', '')}",
      display_name: "Student #{class_level_name}",
      password: 'passwordpassword',
      affiliations_attributes: [
        { name: 'student' },
        { name: 'member' },
        { name: 'employee' }
      ]
    )

    create(:profile,
      user: user,
      preferred_first_name: user.first_name,
      preferred_last_name: user.last_name,
      campus_employee: true,
      school: create(:school),
      campus: create(:campus),
      grad_date: Date.today + 1.year,
      degree: "Master's",
      umid: format('%08d', rand(10000000..99999999)),
      home_address: create(:address, address_type: create(:address_type, :home)),
      campus_address: create(:address, address_type: create(:address_type, :campus))
    )

    user
  end

  # Employee can be [staff, employee, member, alum]
  def create_employee
    user = create(:user,
      email: "employee_#{SecureRandom.hex(4)}@example.com",
      first_name: "Employee",
      last_name: "Staff",
      uniqname: "empstaff#{SecureRandom.hex(4)}",
      uid: "empstaff#{SecureRandom.hex(4)}",
      display_name: "Employee Staff",
      password: 'passwordpassword',
      affiliations_attributes: [
        { name: 'staff' },
        { name: 'employee' },
        { name: 'member' }
      ]
    )

    user
  end
end
