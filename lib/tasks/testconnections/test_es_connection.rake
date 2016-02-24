# lib/tasks/testconnections/test_es_connection.rake
namespace :testconnections do
  desc 'Test ES Connection'
  task test_es_connection: :environment do
    success = ConnectionTester.test_es_connection
    if success
      puts I18n.t 'es_connection'
    else
      puts I18n.t 'no_es_connection'
    end
  end
end
