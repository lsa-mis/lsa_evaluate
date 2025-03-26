class TestMailer < ApplicationMailer
  def test_email
    mail(
      to: 'test-t68vvtnfc@srv1.mail-tester.com',
      subject: 'Test Email from LSA Evaluate'
    )
  end
end
