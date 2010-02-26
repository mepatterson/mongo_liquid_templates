class DynamicTemplate
  include MongoMapper::Document
  
  key :path,  String, :required => true, :index => true
  key :body,  String, :required => true
  key :parsed, Binary
  timestamps!
  
  before_save :preparse
  
  def parsed
    read_attribute(:parsed).to_s
  end
  
  def preparse
    self.parsed = Marshal.dump(Liquid::Template.parse(body))
  end
  
end
