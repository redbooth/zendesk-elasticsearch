require 'zd_object'

# Class based interface for Ticket Objects in the Zendesk API
# This structure assumes they are from Elasticsearch results
class ZDTicket < ZDObject
  include Named

  # store the ticket hash
  def initialize(ticket_hash)
    super ticket_hash
  end

  # The ZD internal ID of the current assignee
  def assignee_id
    val_or_alternate('assignee_id', '')
  end

  # The ID of thhe ticket owner (the current assignee)
  def owner
    assignee_id
  end

  # The ZD internal ID of the requester
  def requester_id
    val_or_alternate('requester_id', '')
  end

  # The ZD internal ID of the submitter
  def submitter_id
    val_or_alternate('submitter_id', '')
  end

  # the url to access the ticket at Zendesk
  def url
    "https://#{ZENDESK_HOST_NAME}/agent/tickets/#{id}"
  end

  # the title of the ticket (ZD refers to this as the subject)
  def title
    subject
  end

  # the subject of the ticket
  def subject
    val_or_alternate('subject', '')
  end

  # the ZD internal id of the organization that created the ticket
  def organization_id
    val_or_alternate('organization_id', '')
  end

  # the free-text status of the ticket
  def status
    val_or_alternate('status', '')
  end

  # the free-text priority of the ticket
  def priority
    val_or_alternate('priority', '')
  end

  # the free text ticket type
  def type
    val_or_alternate('type', '')
  end

  # an array of ZDPost objects (comments) on the ticket
  def posts
    build_posts if @posts.nil?
    @posts
  end

  # returns an array of highlighted text to
  # use in the ticket preview
  # Highlighed previews are only available if
  # the Elasticsearch query is configured to
  # return them
  def comment_preview_highlight
    comment_array = []
    comments = get_highlights('comments', nil)
    comments = get_highlights('subject', nil) if comments.nil?
    comments = get_highlights('organization_name', nil) if comments.nil?
    comments = get_highlights('id_string', []) if comments.nil?
    comments.each do |comment|
      comment_array.push("... #{comment} ...")
    end
    comment_array
  end

  # TODO: use this
  def created_at
    val_or_alternate('created_at', '')
  end

  def updated_at
    val_or_alternate('updated_at', '')
  end

  # An array of tags attached to the post
  def tags
    val_or_alternate('tags', [])
  end

  private

  # Parses the Query response hash to
  # get text highlighted text from
  # a particular node
  def get_highlights(node, alt)
    begin
      comments = @hash['highlight'][node]
    rescue
      comments = nil
    ensure
      comments = alt if comments.nil?
    end
    comments
  end

  # populates @post from the comments stored in
  # the 'raw_comments' field of the returned
  # tickets
  def build_posts
    post_objects = []
    raw_posts = val_or_alternate('raw_comments', [])
    raw_posts.each do |raw_post|
      post = ZDPost.new(raw_post)
      post_objects.push(post) if post.valid?
    end
    # put the most recent posts at the top
    @posts = post_objects.reverse
  end

  # this is overridden because the hash
  # comes from Elasticsearch, not Zendesk
  # The structure of the returned hash is
  # a little different. The query responses
  # are stored in a '_source' node
  def val_or_alternate(param, alt)
    return alt if @hash.nil? || !@hash['_source'].is_a?(Hash)
    value = @hash['_source'][param]
    return alt if value.nil?
    alt.is_a?(String) ? value.to_s : value
  end
end
