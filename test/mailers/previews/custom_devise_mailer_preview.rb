class CustomDeviseMailerPreview < ActionMailer::Preview
  def password_change
    user = User.first || User.create!(
      email: 'test@example.com',
      password: 'password123',
      first_name: 'Test',
      last_name: 'User'
    )
    CustomDeviseMailer.password_change(user)
  end
end
