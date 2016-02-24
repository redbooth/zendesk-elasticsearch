# A class-based interface into Zendesk Organization objects
class ZDOrganization < ZDObject
  include Named
  def initialize(org_hash)
    super(org_hash)
  end
end
