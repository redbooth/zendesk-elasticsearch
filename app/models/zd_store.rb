# A cache for objects that may need to be dynamically loaded from
# the Zendesk API
class ZDStore
  def initialize(route, use_class, object_name, expires_in: 12.hours)
    @route       = route
    @use_class   = use_class
    @cache_name  = @use_class.name
    @object_name = object_name
    @expires_in  = expires_in
  end

  # Builds a hash containing ZDObjects for use in building views.
  # If the objects are already available in the Rails cache,
  # retrieve them from the cache, otherwise retrieve them
  # from Zendesk.
  #
  # returns a hash in the form:
  # { '<object #1 ID>' => <ZDObject Subclass>,
  #   '<object #1 ID>' => <ZDObject Subclass> }
  #
  # id_array: An Array or Set contining object IDs to retrieve
  #
  def get_objects(ids)
    fail(ArgumentError,
         'ids paramater must be Array or Set',
         caller) unless ids.is_a?(Array) || ids.is_a?(Set)
    # loop through each object and determine if we have it already.
    # If we do, add it to the return hash
    return_hash = {}
    missing_objects = []
    ids.each do |id|
      read_object_from_cache!(id, missing_objects, return_hash)
    end

    return_hash.merge!(retrieve_missing_objects(missing_objects))
    return_hash.merge!(invalid_object_hash)
    return_hash
  end

  private

  def read_object_from_cache!(id, missing_objects, found_objects)
    object = Rails.cache.read([@cache_name, "/#{id}"].join(''))
    if object.nil?
      # we don't have a object, lets grab it
      missing_objects.push(id)
    else
      # we do have a object
      found_objects[id.to_s] = object
    end
    object
  end

  def invalid_object_hash
    { '' => @use_class.new({}) }
  end

  def retrieve_missing_objects(missing_objects)
    return_hash = {}
    if missing_objects.size != 0
      object_hashes = get_objects_from_zendesk(missing_objects)
      unless object_hashes.nil?
        new_objects = cache_missing_objects(object_hashes)
        return_hash.merge!(new_objects)
      end
    end
    return_hash
  end

  # GETs objects from Zendesk and returns them as a hash
  #
  # id_array: an array if object IDs to GET from Zendesk
  #
  # returns the JSON response from the Zendesk API as an array
  # of object hashes or nil if there were issues retrieving them
  #
  # use cache_missing_objects to store the results into the
  # Rails cache
  def get_objects_from_zendesk(id_array)
    # get the route
    params   = { ids: id_array.join(',') }
    request  = ZENDESK_REQUEST_BUILDER.build(request_type: 'GET',
                                             route: @route,
                                             param_hash: params)
    # try to load the object
    begin
      response = nil
      ZENDESK_HTTP_CONNECTION.start do |http_connection|
        response = http_connection.request(request)
      end
      response = JSON.parse(response.body)[@object_name]
    rescue
      return nil
    end

    # make sure that the object makes some sort of sense
    return nil if response.nil? || response.size < 1
    response
  end

  # Caches objects into the Rails cache
  #
  # object_hashes: An array of hashes
  # useful for building ZDObjects. These hashes should
  # be generated using get_objects_from_zendesk
  def cache_missing_objects(object_hashes)
    new_objects = {}
    object_hashes.each do |object_hash|
      object = @use_class.new(object_hash)
      next unless object.valid?
      id = object.id
      new_objects[id.to_s] = object
      Rails.cache.write([@cache_name, "/#{id}"].join(''),
                        object,
                        expires_in: @expires_in)
    end
    new_objects
  end
end
