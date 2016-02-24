# lib/tasks/updatees/reload_all_tickets.rake
namespace :updatees do
  desc 'Purges ES database of tickets and reloads them'
  task reload_all_tickets: :environment do
    has_zendesk_connection = ConnectionTester.test_zendesk_connection
    has_es_connection      = ConnectionTester.test_es_connection

    if (!has_zendesk_connection) || (!has_es_connection)
      puts I18n.t 'no_zd_es_connection'
      next
    end

    f = ESUpdater.lock_updates
    if f.nil?
      puts I18n.t 'another_process_updating'
      next
    end

    ticket_start_time = ZENDESK_TICKET_START_DATE
    if ESUpdater.valid_start_time?(ticket_start_time.to_i)
      ESUpdater.clear_es_timestamp

      puts I18n.t 'deleting_all_tickets'
      ESUpdater.delete_all_tickets
      puts I18n.t 'all_tickets_deleted'

      puts I18n.t 'reloading_all_tickets'
      ESUpdater.flush_tickets(ticket_start_time.to_i)
      puts I18n.t 'all_tickets_reloaded'
    else
      puts I18n.t 'invalid_ticket_start_date_configuration'
    end

    ESUpdater.unlock_updates(f)
  end
end
