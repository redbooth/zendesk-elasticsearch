# lib/tasks/updatees/set_es_timestamp.rake
namespace :updatees do
  desc 'Sets the last-updated time stamp for pulling new tickets'
  task :set_es_timestamp, [:time_stamp] => :environment do |_t, args|
    time_stamp = args[:time_stamp]

    connection_exists = ConnectionTester.test_es_connection
    valid_time_stamp  = ESUpdater.valid_start_time?(time_stamp.to_i)

    # Check for valid timestamp
    unless valid_time_stamp
      puts I18n.t 'invalid_timestamp'
      next
    end

    # check for the connection
    unless connection_exists
      puts I18n.t 'no_es_connection'
      next
    end

    # update the timestamp
    f = ESUpdater.lock_updates
    if f.nil?
      puts I18n.t 'another_process_updating'
      next
    end
    if ESUpdater.set_es_timestamp(time_stamp.to_i)
      puts I18n.t 'timestamp_updated'
    else
      puts I18n.t 'timestamp_not_updated'
    end
    ESUpdater.unlock_updates(f)
  end
end
