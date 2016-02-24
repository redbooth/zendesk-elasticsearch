require 'net/http'
require 'rubygems'
require 'json'
require 'set'

# Controller for the Index Route
class IndexController < ApplicationController
  def index
    search_builder      = SearchBuilder.new(SEARCH_DEFINITION)
    @search_description = search_builder.search_description
  end

  # route method for updating search results
  def update_search_results
    # TODO: Put the search string in a JSON payload so it is not in a URL
    search_string = search_result_params['text']
    return if search_string.nil? || (search_string.eql? '')

    # post the request
    search_results = search_for_term(search_string)

    # abandon ship if the response is bad
    return if search_results.nil?

    # build ticket objects and
    # retrive helpers from the Rails cache/
    # Zendesk API
    build_tickets(search_results)

    respond_to do |format|
      format.js {}
    end
  end

  private

  # whitelist the 'text' paramater for update_search_results
  def search_result_params
    params.permit('text')
  end

  # Post a search to the ES server
  def search_for_term(string)
    search_builder = SearchBuilder.new(SEARCH_DEFINITION)
    payload        = search_builder.search_body(string)
    request        = ES_REQUEST_BUILDER.build(request_type: 'POST',
                                              route: '/tickets/_search',
                                              payload: payload)

    # Assume the response is valid. Abandon if it is not.
    begin
      response      = ES_HTTP_CONNECTION.request(request)
      response_code = response.code.to_s
      response_body = JSON.parse(response.body)
    rescue
      return nil
    end
    response_code.eql?('200') ? response_body : nil
  end

  # build the list of objects for the view
  def build_tickets(json_hash)
    return_tickets = []
    user_ids = Set.new
    organization_ids = Set.new

    # peruse the hash to build ticket objects and collect
    # the other necessary objects
    ticket_results = parse_ticket_results(json_hash)

    # add each ticket result as a ticket object to the array
    # and collect helper objects
    ticket_results.each do |ticket|
      ticket = ZDTicket.new(ticket)
      return_tickets.push(ticket)

      # collect ticket's organizations
      organization_ids.merge(organization_ids_to_collect(ticket))

      # collect ticket's users
      user_ids.merge(user_ids_to_collect(ticket))
    end

    # populate the controller's instance variables
    set_instance_variables(user_ids, organization_ids, return_tickets)
  end

  private

  def organization_ids_to_collect(zd_ticket)
    return_ids = []
    org_id = zd_ticket.organization_id
    return_ids.push(org_id) unless org_id.eql? ''
    return_ids
  end

  def user_ids_to_collect(zd_ticket)
    return_ids = []
    ticket_user_ids = [zd_ticket.owner, zd_ticket.requester_id]
    ticket_user_ids.each do |user_id|
      return_ids.push(user_id) unless user_id.eql? ''
    end
    return_ids
  end

  def parse_ticket_results(json_hash)
    return json_hash['hits']['hits']
  rescue
    return []
  end

  def set_instance_variables(user_ids, organization_ids, tickets)
    @users         = ZENDESK_USER_STORE.get_objects(user_ids)
    @organizations = ZENDESK_ORG_STORE.get_objects(organization_ids)
    @tickets       = tickets
  end
end
