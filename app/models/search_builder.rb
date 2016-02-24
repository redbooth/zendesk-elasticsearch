# Builds a JSON payload to pass to Elasticsearch from a YAML file
# that describes the search
class SearchBuilder
  def initialize(file_contents)
    @search_file_contents = file_contents
  end

  def search_description
    # attempt to load the configuration file using
    # an empty search string
    description = ''
    begin
      local_binding = get_binding('')
      yaml = ERB.new(@search_file_contents).result(local_binding)
      
      # try to get the description
      description = YAML.load(yaml)['search_description']
    rescue
      description = ''
    end
    description
  end

  def search_body(search_string)
    return_json = nil

    # attempt to load and evaluate the YAML search description
    begin
      # Evaluate the YAML to determine the search structure
      local_binding = get_binding(search_string.inspect)
      yaml = ERB.new(@search_file_contents).result(local_binding)

      # return the hash
      return_json = YAML.load(yaml)['search_definition'].to_json
    rescue
      return_json = nil
    end
    return_json
  end

  private

  # return a binding context for evaluating the search string
  def get_binding(search_string)
    binding
  end
end
