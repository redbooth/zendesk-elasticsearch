# lib/tasks/updatees/delete_tickets.rake
namespace :updatees do
  desc 'Purges ES database of tickets'
  task delete_tickets: :environment do
    connection_exists = ConnectionTester.test_es_connection
    if connection_exists
      f = ESUpdater.lock_updates
      if f.nil?
        puts I18n.t 'another_process_updating'
        next
      end
      puts I18n.t 'deleting_all_tickets'
      ESUpdater.delete_all_tickets
      puts I18n.t 'all_tickets_deleted'
      ESUpdater.unlock_updates(f)
    else
      puts I18n.t 'no_es_connection'
    end
  end
end
