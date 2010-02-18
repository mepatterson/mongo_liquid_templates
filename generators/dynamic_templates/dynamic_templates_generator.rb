class DynamicTemplatesGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.directory 'app/models'
      m.template 'model.rb', 'app/models/dynamic_template.rb'
    end
  end
  
  protected
  
  def banner
    "Usage: #{$0} dynamic_templates"
  end
end