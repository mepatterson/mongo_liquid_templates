class DynamicTemplate
  include MongoMapper::Document
  
  key :path,  String, :required => true, :indexed => true
  key :body,  String, :required => true
  timestamps!
  
end
