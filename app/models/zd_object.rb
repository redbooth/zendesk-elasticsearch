# ZD Objects are lightwight interfaces into the hashes returned by
# queries to the the Zendesk API.
#
# It is generaly not useful to instantiate ZDObjects directly. Rather subclass
# ZDOject for kind of Zendesk entity you need
class ZDObject
  def initialize(hash)
    unless hash.is_a? Hash
      fail ArgumentError, 'ZDObjects must be initialized with a Hash', caller
    end
    @hash = hash
  end

  # returns the zendesk internal ID if it exists
  def id
    val_or_alternate('id', '')
  end

  # indicates if the object is valid
  # an object is valid its store is
  # initialized and it has a
  # Zendesk internal ID. All other keys are
  # optional
  def valid?
    (!@hash.nil?) && (!id.eql? '')
  end

  private

  # helper method accessing keys in the hash
  def val_or_alternate(key, alt)
    return alt if @hash.nil? || @hash[key].nil?
    value = @hash[key]
    alt.is_a?(String) ? value.to_s : value
  end
end

# a mixin foor all ZD Objects with names
module Named
  def name
    val_or_alternate('name', '')
  end
end
