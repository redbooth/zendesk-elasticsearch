# lib/tasks/testconnections/test_zendesk_connection.rake
namespace :testconnections do
  desc 'Test Zendesk Connection'
  task test_zendesk_connection: :environment do
    success = ConnectionTester.test_zendesk_connection
    if success
      puts I18n.t 'zd_connection'
    else
      puts I18n.t 'no_zd_connection'
    end
  end
end
