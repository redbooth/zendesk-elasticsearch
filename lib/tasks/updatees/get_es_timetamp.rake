# lib/tasks/updatees/get_es_timestamp.rake
namespace :updatees do
  desc 'Gets the last-updated time stamp for pulling new tickets'
  task get_es_timestamp: :environment do
    connection_exists = ConnectionTester.test_es_connection
    if connection_exists
      time_stamp = ESUpdater.get_es_timestamp
      puts [I18n.t('next_timestamp'), " #{time_stamp}"].join('')
    else
      puts I18n.t 'no_es_connection'
    end
  end
end
