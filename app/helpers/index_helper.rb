require 'time'

# Index-scope view helpers
module IndexHelper
  # Formats a user name given a ZDUser ID
  def user_name(id)
    name(id, @users)
  end

  # Formats an organization name given a ZDOrganization ID
  def organization_name(id)
    name(id, @organizations)
  end

  # Fomats a ticket created at date given a ZDTicket
  def ticket_created_at(zd_ticket)
    return '' unless zd_ticket.is_a?(ZDTicket)
    format_date(zd_ticket.created_at)
  end

  # Formats a ticket updated at date given a ZDTicket
  def ticket_updated_at(zd_ticket)
    return '' unless zd_ticket.is_a?(ZDTicket)
    format_date(zd_ticket.updated_at)
  end

  # Format a Zendesk tag for display
  def format_tag(tag_string)
    return '' unless tag_string.is_a?(String)
    # This capitalizes the first letter of _ delimited tokens
    # then replaces the _s with spaces
    tag_string.split('_').map(&:capitalize).join(' ')
  end

  # Chooses a label for the ticket status based on the
  # status to relect Zendesk coloring
  def status_label_class(tag_string)
    case tag_string
    when 'new'
      return 'label-warning'
    when 'open'
      return 'label-danger'
    when 'pending'
      return 'label-info'
    else
      return 'label-default'
    end
  end

  # Formats a ticket display title
  def ticket_display_title(zd_ticket)
    return '' unless zd_ticket.is_a?(ZDTicket)
    "#{zd_ticket.id} - #{zd_ticket.title}"
  end

  private

  # formats a name from an object with an ID in a given collection
  def name(id, object_hash)
    return '' unless valid_input_for_name?(id, object_hash)
    entity = object_hash[id]
    entity.nil? ? '' : entity.name
  end

  # determines if the paramaters given to get a name
  # are sane
  def valid_input_for_name?(id, object_hash)
    (!id.nil?) && (!id.eql? '') && (!object_hash.nil?)
  end

  def format_date(date)
    return '' if date.eql? ''
    Date.parse(date)
  end
end
