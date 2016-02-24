# A class-based interface into Zendesk Comment objects
class ZDUser < ZDObject
  include Named

  def initialize(user_hash)
    super user_hash
  end

  # the user's email address
  def email
    val_or_alternate('email', '')
  end
end
