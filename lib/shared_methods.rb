module SharedMethods
  $APP_ROOT = File.expand_path(File.dirname(File.dirname(__FILE__)))

  def credentials
    YAML.load_file("#{$APP_ROOT}/credentials.yaml")
  end

  def format_json(item)
    JSON.pretty_generate(JSON.parse(item.to_json))
  end

end