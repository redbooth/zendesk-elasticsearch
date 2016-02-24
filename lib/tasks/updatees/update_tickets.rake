# lib/tasks/updatees/update_tickets.rake
namespace :updatees do
  desc 'Updates tickets based on the most recent timestamp in the ES database.'
  task update_tickets: :environment do
    has_zendesk_connection = ConnectionTester.test_zendesk_connection
    has_es_connection      = ConnectionTester.test_es_connection

    f = ESUpdater.lock_updates
    if f.nil?
      puts I18n.t 'another_process_updating'
      next
    end

    if (!has_zendesk_connection) || (!has_es_connection)
      puts I18n.t 'no_zd_es_connection'
      next
    end

    # Choose a ticket start time, either what
    # is in ES or the start time otherwise
    ticket_start_time = ESUpdater.get_es_timestamp
    if ESUpdater.valid_start_time?(ticket_start_time.to_i)
      puts [I18n.t('updating_tickets_from_time'),
            ": #{Time.at(ticket_start_time)}"].join('')
    elsif ESUpdater.valid_start_time?(ZENDESK_TICKET_START_DATE.to_i)
      ticket_start_time = ZENDESK_TICKET_START_DATE
      puts [(I18n.t 'updating_tickets_from_config'),
            ": #{Time.at(ticket_start_time)}"].join('')
    else
      puts I18n.t 'no_timestamp_for_updates'
      next
    end

    puts I18n.t 'updating_tickets'
    ESUpdater.flush_tickets(ticket_start_time.to_i)
    puts I18n.t 'tickets_updated'

    ESUpdater.unlock_updates(f)
  end
end
