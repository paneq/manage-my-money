require 'test_helper'

class RegisterMailerTest < ActiveSupport::TestCase
#  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
#  CHARSET = "utf-8"
#
#  include ActionMailer::Quoting
#
#  def setup
#    ActionMailer::Base.delivery_method = :test
#    ActionMailer::Base.perform_deliveries = true
#    ActionMailer::Base.deliveries = []
#
#    @expected = TMail::Mail.new
#    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
#    @expected.mime_version = '1.0'
#  end
#
#  def test_confirm
#    @expected.subject = 'RegisterMailer#confirm'
#    @expected.body    = read_fixture('confirm')
#    @expected.date    = Time.now
#
#    assert_equal @expected.encoded, RegisterMailer.create_confirm(@expected.date).encoded
#  end
#
#  def test_sent
#    @expected.subject = 'RegisterMailer#sent'
#    @expected.body    = read_fixture('sent')
#    @expected.date    = Time.now
#
#    assert_equal @expected.encoded, RegisterMailer.create_sent(@expected.date).encoded
#  end
#
#  private
#    def read_fixture(action)
#      IO.readlines("#{FIXTURES_PATH}/register_mailer/#{action}")
#    end
#
#    def encode(subject)
#      quoted_printable(subject, CHARSET)
#    end
end
