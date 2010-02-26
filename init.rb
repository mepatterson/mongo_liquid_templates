require File.join(File.dirname(__FILE__), 'lib', 'mongo_liquid_templates')
require File.join(File.dirname(__FILE__), 'lib', 'database_file_system')

# load all the app-structure stuff

%w{ models controllers helpers }.each do |dir|
  path = File.join(File.dirname(__FILE__), 'lib', 'app', dir)
  $LOAD_PATH << path
  ActiveSupport::Dependencies.load_paths << path
  ActiveSupport::Dependencies.load_once_paths.delete(path)
end

ActionController::Base.send :include, MongoLiquidTemplates
ActionView::Base.send :include, MongoLiquidTemplates