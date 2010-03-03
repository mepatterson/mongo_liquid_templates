module MongoLiquidTemplates

  class DatabaseFileSystem
    
    def initialize( assigns = {}, options = {} )
      @_assigns = assigns
      @_options = options
    end
    
    # Called by Liquid to retrieve a template file from mongo
    def read_template_file(template_path)    
      if mongotmpl = DynamicTemplate.find_by_path(template_path)
        mongotmpl.parsed ? Marshal.load(mongotmpl.parsed) : mongotmpl.body
      else
        raise "Could not find template '#{template_path}'; maybe you need to add this template to mongo's dynamic_templates collection?"
      end
    end
    
  end
end
  