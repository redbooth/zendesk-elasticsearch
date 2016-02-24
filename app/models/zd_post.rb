# A class-based interface into Zendesk Comment objects
class ZDPost < ZDObject
  def initialize(post_hash)
    super post_hash
  end

  # returns a string of HTML with the body of the post
  def html_body
    val_or_alternate('html_body', '')
  end

  # indicates of the post is public (visable to end users and agents)
  # or private (only visable to agents)
  def public?
    val_or_alternate('public', true)
  end

  # indicates if the post is private (see definition of public?)
  def private?
    !public?
  end
end
