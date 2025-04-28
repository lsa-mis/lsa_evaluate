class TestMailerPreview < ActionMailer::Preview
  def test_email
    TestMailer.test_email('test@example.com')
  end
end
