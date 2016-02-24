require 'rubygems'
require 'json'
require 'set'
require 'nokogiri'
require 'timeout'
require 'fileutils'

# The defines methods useful for updating the Elasticsearch cluster with new ticket information.
# Public methods in this class are appropriate for calling from Rake tasks. Use the process locking 
# functionality in Rake tasks to prevent race conditions.
class ESUpdater
  # Call this method from a Rake task to reload all tickets that were updated from the given time
  # stamp. Note that the time stamp in Unix time - number of seconds since the Unix epoch
  def self.flush_tickets(start_time_stamp)
    # Don't do anything if the start_time_stamp is invalid
    return unless self.valid_start_time?(start_time_stamp.to_i)

    # Grab the the current time to update the ES database with at the
    # end of the transaction
    now_ts  = Time.now.to_i

    # load the tickets from the Zendesk API into local memory
    tickets = load_tickets_since(start_time_stamp)

    # Send each ticket to the ES cluster
    success = false
    unless tickets.nil?
      # set success if ALL tickets were loaded
      # successfully
      success = send_tickets(tickets)
    end

    # store the timestamp in ES. Worse things could happen than this failing - which is why it can 
    # fail a lot. If it does, we'd just an request an unnecessairlly high number of tickets next 
    # time this is called.
    if self.valid_start_time?(now_ts.to_i) && !tickets.nil? && success
      set_es_timestamp(now_ts)
    end
    success
  end

  # Call this method from a Rake task to purge the ticket index from the Elasticsearch database
  def self.delete_all_tickets
    route   = '/tickets/'
    request = ES_REQUEST_BUILDER.build(request_type: 'DELETE',
                                       route: route)

    # get the response
    response = ES_HTTP_CONNECTION.quick_request(request)
    
    code = response.try(:code).try(:to_s) || ''
    code.eql?('200')
  end

  # Implementation of process locking. Before running any task that modifies the contents of the 
  # ES database, lock the file
  def self.lock_updates
    # try to be the process that gets to update the tickets
    begin
      f = nil
      Timeout.timeout(5) do
        # try to open and lock the file within 5 seconds
        FileUtils.mkdir_p "#{Rails.root}/tmp/pids"
        f = File.new("#{Rails.root}/tmp/pids/es_update.pid",
                     File::RDWR|File::CREAT)
        f.flock(File::LOCK_EX)
        value = Process.pid
        f.rewind
        f.write("#{value}\n")
        f.flush
        f.truncate(f.pos)
      end
    rescue
      f.close if !f.nil? && !f.closed?
      return nil
    end
    f
  end

  # After the process has completed updating the database, unlock the process
  def self.unlock_updates(f)
    f.close
    return true
  rescue
    return false
  end

  # Timestamps must be greater than 0
  def self.valid_start_time?(time_stamp)
    time_stamp.to_i > 0
  end

  # Clear the timestamp stored in Elasticsearch (Causes the next update tickets call to reload from
  # the begnning of time (as specified in the configuration))
  def self.clear_es_timestamp
    route = '/helpers/helper/0'
    request = ES_REQUEST_BUILDER.build(request_type: 'DELETE',
                                       route: route)
    response = ES_HTTP_CONNECTION.quick_request(request)
    
    code = response.try(:code).try(:to_s) || ''
    code.eql?('200')
  end

  # Sets the timestamp in the elasticsearch database
  def self.set_es_timestamp(timestamp)
    fail(ArgumentError, 'No timestamp provided', caller) if timestamp.nil?

    route = '/helpers/helper/0'
    params  = { start_time: timestamp }

    request = ES_REQUEST_BUILDER.build(request_type: 'POST',
                                       route: route,
                                       payload: params.to_json)
    response = ES_HTTP_CONNECTION.quick_request(request)
    
    code = response.try(:code).try(:to_s) || ''
    code.eql?('200')
  end

  # Gets the current timestamp stored in the Elasticsearch cluster
  def self.get_es_timestamp
    route   = '/helpers/helper/0'
    request = ES_REQUEST_BUILDER.build(request_type: 'GET',
                                       route: route)
    response = ES_HTTP_CONNECTION.quick_request(request)

    time_stamp = nil
    begin
      response_body_hash = JSON.parse(response.body)
      time_stamp = response_body_hash['_source']['start_time']
    rescue
      time_stamp = nil
    end
    time_stamp
  end

  # This method performs the following operations to send
  # tickets to the ES Cluster:
  # 1) Opens a connection to the cluster
  # 2) For each ticket:
  #    * inserts the id into a free-text field to allow indexing on the ID regardless of ES
  #      configuration of the ID field
  #    * adds comments as raw HTML and rendered text to the payload
  #    * adds organization names to the payload to make them searchable
  #    * POSTs the ticket to the ES cluster
  #
  # returns: true if ALL tickets were successfully submitted and false otherwise
  def self.send_tickets(tickets)
    all_tickets_succeeded = true
    ES_HTTP_CONNECTION.start do |http_connection|
      puts "Loading #{tickets.size} tickets..."
      ticket_set = Set.new
      progress_bar = ProgressBar.create(title: 'Tickets',
                                        starting_at: 0,
                                        total: tickets.size)
      tickets.each do |ticket|
        # update the progress bar
        progress_bar.increment

        # skip if we have no ticket id
        ticket_id = ticket['id']
        next if ticket_id.nil?
        next if ticket_set.include?(ticket_id)
        ticket_set.add(ticket_id)

        # store the id in a string
        ticket['id_string'] = ticket_id.to_s

        # process comments
        comments = process_comments(ticket_id)
        # get the flattened comments for searching over
        ticket['comments'] = comments[:flat_comments]
        ticket['raw_comments'] = comments[:raw_comments]

        # process organizations - these are partially indexed so that org names can be looked up.
        # they are cached for later
        org_id = ticket['organization_id']
        unless org_id.nil? || org_id.eql?('')
          org_object = ZENDESK_ORG_STORE.get_objects([org_id])
          begin
            org_name = org_object[org_id.to_s].name
            ticket['organization_name'] = org_name unless org_name.eql?('')
          rescue
            ticket.delete('organization_name')
          end
        end

        # send the ticket to ES. If the send failed, flag the entire process
        all_tickets_succeeded = false unless send_ticket(ticket,
                                                         http_connection)
      end
    end
    all_tickets_succeeded
  end

  # POSTs a single ticket hash to the ES cluster for indexing.
  # returns: true if the operation was successful and false otherwise
  def self.send_ticket(ticket_hash, open_http_connection)
    ticket_id = ticket_hash['id']
    return false if ticket_id.nil? # shouldn't happen

    route    = ['/tickets/ticket/', ticket_id].join('')
    request  = ES_REQUEST_BUILDER.build(request_type: 'POST',
                                        route:         route,
                                        payload:       ticket_hash.to_json)
    begin
      response = open_http_connection.request(request)
    rescue
      return false
    end
    response.code.to_s.eql? '200'
  end

  # Grab the comments for each ticket and add them to the ticket hash that is posted to the 
  # Elasticsearch cluster (becasue comments aren't included in the Zendesk API's ticket resource).
  # We store both the raw HTML comments and the HTML comments rendered as text. The HTML comments
  # are for display, and the flattened comments are for searching on.
  def self.process_comments(ticket_id)
    flat_comments = [] # place for updated comments
    raw_comments  = []

    # Get the comments from the Zendesk API
    comments = get_ticket_comments(ticket_id)
    begin
      comments = JSON.parse(comments.body)['comments']
    rescue
      comments = []
    end
    comments = [] if comments.nil?

    # for each comment, render as text and and store both the rendered and raw comments
    comments.each do |comment|
      comment_body = comment['html_body']
      unless comment_body.nil?
        flat_comments.push(sanitize_comment_string(comment_body))
        raw_comments.push(comment)
      end
    end
    { flat_comments: flat_comments, raw_comments: raw_comments }
  end

  # Render a HTML comment as a string, and eplace any instance of whitespace with a single
  # space. This procedure is to make the comments searchable
  def self.sanitize_comment_string(comment_html)
    comment_string = Nokogiri::HTML(comment_html).text
    comment_string.gsub(/[[:space:]]/, ' ')
  end

  # Gets the ticket comments associated with a ticket ID from the Zendesk API
  def self.get_ticket_comments(ticket_id)
    # define the route
    route = "/api/v2/tickets/#{ticket_id}/comments.json"

    # build the request
    request = ZENDESK_REQUEST_BUILDER.build(request_type: 'GET',
                                            route: route)
    ZENDESK_HTTP_CONNECTION.quick_request(request)
  end

  # Determines the next time to use for querying for tickets based on the value in the response hash
  def self.time_for_additional_request(response_body_hash, previous_time)
    next_page = response_body_hash['next_page']
    return nil if next_page.nil? || next_page.eql?('')

    # handle times that don't requre new data fetching
    time = response_body_hash['end_time']
    return nil if time.nil? || time < 0
    return nil if time == previous_time
    return nil if (Time.now.to_i - time).abs < 360
    time
  end

  # Loads tickets from Zendesk that were updated since a given time
  def self.load_tickets_since(time)
    ticket_set = Set.new

    loop do
      puts "Requesting tickets created after: #{Time.at(time)}"

      response = load_tickets_since_helper(time)

      # give up if the response can't be parsed
      begin
        response_body_hash = JSON.parse(response.body)
      rescue
        ticket_set = nil
        break
      end

      # grab the tickets from the hash
      requested_tickets = response_body_hash['tickets']
      requested_tickets = [] if requested_tickets.nil?

      ticket_set = ticket_set.merge(requested_tickets)

      # Determine if we need to get more tickets
      new_time = time_for_additional_request(response_body_hash,
                                             time)
      break if new_time.nil?
      time = new_time
    end
    return nil if ticket_set.nil? || ticket_set.empty?
    ticket_set
  end

  # request tickets modified since a given time return nil if response indicates failure
  def self.load_tickets_since_helper(start_time)
    # define the route
    route = '/api/v2/incremental/tickets.json'

    # put the start time in a param hash
    params  = { start_time: start_time }

    # build the request
    request = ZENDESK_REQUEST_BUILDER.build(request_type: 'GET',
                                            route:        route,
                                            param_hash:   params)
    response = ZENDESK_HTTP_CONNECTION.quick_request(request)
    ticket_response(response, start_time)
  end
  
  # Process the response to the ticket request. Here we have several options:
  # 1. The response object was nil => return nil
  # 2. We get a rate limited warning from Zendesk => Wait for an amount of time recommended by the
  #    Zendesk API
  # 3. Success => return the response object for parsing
  # 4. Any other response => Asume failure
  def self.ticket_response(response, start_time)
    return_val = nil
    if response.nil?
      return_val = nil
    elsif response.code.to_s.eql? '429' # Handle rate limits
      # Sleep the process a certain amount of time to account for rate lmiiting we can give the API
      # a bit of a rest
      wait_val = response['Retry-After'].to_i * 1.2 + 1
      puts "Waiting #{wait_val} seconds to retry..."
      sleep(wait_val)
      # execute the request again
      return load_tickets_since_helper(start_time)
    elsif !(response.code.to_s.eql? '200') # Handle any other response
      return_val = nil
    else
      return_val = response
    end
    return_val
  end
end
