module MongoLiquidTemplates
  
  def load_custom_drops
    all_drops = {}
    path = File.join(Rails.root, 'app', 'liquid_drops')
    for filepath in Dir["#{path}/*.rb"]
      file  = File.basename(filepath, ".rb")
      klass = file.camelize.constantize
      object_klass = file.split(/_drop$/).to_s
      all_drops[object_klass.to_sym] = klass.new
    end
    all_drops
  end
 
  def render_liquid( path, assigns={} )
    _controller_name          = assigns.delete(:controller)      || self.controller_name
    _model_name               = _controller_name.singularize
    _collection_variable_name = (assigns.delete(:collection)     || "@#{_controller_name}").to_s # @comments
    _object_variable_name     = (assigns.delete(:object)         || "@#{_model_name}").to_s      # @comment
    _parent_name              = respond_to?(:parent) ? "#{parent.class.name.underscore}_" : nil
    _namespace                = assigns.include?(:namespace) ? "#{assigns[:namespace]}_" : nil
    instance_variables.each do |variable|
      # discovers variables and path for index action
      case variable
      when _collection_variable_name:
        assigns.merge!( "collection"     => instance_variable_get(variable) ) 
        assigns.merge!( _controller_name => instance_variable_get(variable) ) 
      # discovers variables for all the other actions
      when _object_variable_name:
        # post_comment_path(@post, @comment) or comment_path(@comment)
        _object_named_route = "#{_namespace}#{_parent_name}#{_model_name}_path(#{_parent_name ? 'parent, ' : nil}instance_variable_get(variable))" 
 
        assigns.merge!( "object_path" => eval(_object_named_route) ) rescue nil
        assigns.merge!( "object"      => instance_variable_get(variable) )
        assigns.merge!( _model_name   => instance_variable_get(variable) ) 
      end
    end

    # if this is a nested resource, override the 'parent' method to return the parent object
    if _parent_name
      # posts_path(@post)
      assigns.merge!( "parent"      => parent )
      assigns.merge!( "parent_path" => eval("#{_namespace}#{_parent_name}path(#{_parent_name ? 'parent' : nil})") ) rescue nil 
    end
    
    # post_comments_path(@posts), new_post_comment_path(@posts)
    # comments_path, new_comment_path
    _collection_named_route = "#{_namespace}#{_parent_name}#{_controller_name}_path(#{_parent_name ? 'parent' : nil})"
    _new_named_route        = "new_#{_namespace}#{_parent_name}#{_model_name}_path(#{_parent_name ? 'parent' : nil})"

    assigns.merge!( "collection_path" => eval(_collection_named_route) ) rescue nil
    assigns.merge!( "new_object_path" => eval(_new_named_route) ) rescue nil

    if assigns["object"] && assigns["object"].id && !assigns["collection"]
      assigns.merge!("collection" => [assigns["object"]])
    end

    _object      = assigns["collection"].try(:first)
    _object_name = if _object
      # create attributes to cache resource paths
      unless _object.respond_to?(:_show_path)
        _object.class.class_eval do
          attr_accessor :_show_path
          attr_accessor :_edit_path
        end
      end
      # override liquid serializer to add the cached resource paths
      if _object.respond_to?(:to_liquid) && !_object.respond_to?(:to_liquid_old)
        _object.class.class_eval do
          alias :to_liquid_old :to_liquid
          def to_liquid
            to_liquid_old.merge(
              'show_path' => self._show_path, 
              'edit_path' => self._edit_path )
          end
        end
      end
      _object.class.name.underscore
    end

    # cache each model named_route into itself
    if assigns["collection"]
      assigns["collection"].each do |_object|
        # post_comment_path(parent, @comment), edit_post_comment_path(parent, @comment)
        # comment_path(@comment), edit_comment_path(@comment)
        _show_path = "#{_namespace}#{_parent_name}#{_object_name}_path(#{_parent_name ? 'parent, ' : nil}_object)"
        _edit_path = "edit_#{_namespace}#{_parent_name}#{_object_name}_path(#{_parent_name ? 'parent, ' : nil}_object)"

        _object._show_path = eval(_show_path)
        _object._edit_path = eval(_edit_path)
      end
    end

    assigns.merge!("form_authenticity_token" => form_authenticity_token)
    
    assigns.merge!(load_custom_drops)
    assigns.merge!({:user => current_user}) if self.respond_to?(:current_user)
    options = { :filters => [self.controller.master_helper_module], :registers => {
      :action_view => self,
      :controller  => self.controller
    } }    
    Liquid::Template.file_system = MongoLiquidTemplates::DatabaseFileSystem.new(assigns.stringify_keys!, options)
    source = Liquid::Template.file_system.read_template_file(path)
    template = Liquid::Template.parse(source)
    template.render(assigns.stringify_keys!, options)
  end
  
end


# allows us to pre-parse Liquid::Template objects for fun and efficiency!
module Liquid
  class Template
    class << self
      def parse(source)
        case source
        when Liquid::Template then source
        else Template.new.parse(source)
        end
      end      
    end
  end
end