module Ink

  # = Controller class
  # 
  # == Usage
  # 
  # Controllers handle incoming requests and decide what to do
  # with them. A controller has access to all incoming data, like
  # POST and GET as well as the config.
  #
  #   class App < Ink::Controller
  #     
  #     def index
  #       redirect_to :controller => "app", :module => "feed", :id => 29382374
  #     end
  #     
  #     def feed
  #       @arg = @params[:id]
  #       @users = []
  #       render :template => "index"
  #     end
  #
  #     def partial
  #       @arg = "foo bar"
  #       render :partial => "part", :standalone => true
  #     end
  #     
  #   end
  #
  # A controller named App should have the filename app.rb and be
  # placed inside the project controller folder. It can have instance
  # methods that are usually refered to as modules.
  # So a route should contain at least a :controller and a :module.
  #
  # In the sample above there are three modules, index redirects
  # to feed, feed renders a template and partial renders a partial.
  # When using a partial inside a template, you do not need the
  # standalone argument, but when you plan to return just the partial,
  # you should add it to the argument string. Rendering returns an
  # interpreted erb instance, which is returned to the calling part of
  # the script, which runs the erb instance. Redirecting forwards
  # an erb instance and passes on the existing @params, after overwriting
  # and setting its hash arguments, so multiple redirecting works.
  #
  # The template is called inside the binding on the controller, which
  # means that all instance variables and methods are available as such.
  #
  # == Templates
  #
  # All templates are to be put into the project views folder, and are
  # to be named name.html.erb, while partials are to be named _anothername.html.erb.
  # It is possible to create subfolders and call the templates via
  # :template => "subfolder/template.html.erb".
  #
  # The index.html.erb template in the controller above looks like this:
  #
  #   <%= render :partial => "part" %>
  #
  # And the _part.html.erb, that is called from the index, is this:
  #
  #   WTF <%= @arg %>!!
  #   <br>
  #
  # When the index module is requested, it will set :id to 29382374.
  # However requesting the feed module, it requires :id to be set as
  # a parameter through the routes.
  #
  # == Routing
  #
  # The routes being evaluated by the dispatcher are simple regular expressions.
  # This example fits the controller from earlier.
  #
  #   root = "/folder"
  #
  #   routes = [
  #     [ /^\/([^\/]+)\/([^\/]+)(\/([0-9]+))?$/, {:controller => "$1", :module => "$2", :id => "$4"} ],
  #     [ /^\/([^\/]+)\/?$/, {:controller => "$1", :module => "index"} ],
  #     [ /^\/?$/, {:controller => "app", :module => "index"} ],
  #   ]
  #
  # Routes are built as a priority list, the first match will be the route taken. All
  # route configurations must include a variable named root, as it will help to create
  # dynamic links within websites. Root is relative to the webserver root. Assume your
  # webserver points to public_html, then routes can be "" for the public_html folder,
  # or "/anysubfolder" which points to anysubfolder. Deeper structures work too.
  #
  # == Linking
  #
  # A controller has the ability to create hyperlinks for you, that will dynamically match
  # the project path etc. (and is also using the root variable from the routes.rb)
  #
  #   link_to "name", "controller", "module", "param1", "param2", {:class => "h1", :id => "14"}
  #
  # The link above will produce this:
  #
  #   <a class="h1" id="14" href="/controller/module/param1/param2/">name</a>
  #
  # So the first entry of the argument array is the hyperlink name, then all
  # following entries are connected as the href string, prefixed by the root variable
  # that is set in the routes.rb. The hash includes the attributes for the <a>-tag.
  #
  # == Pathing
  #
  # A controller also constructs paths for you (and is also using the root variable
  # from the routes.rb), which you can use to dynamically reroute forms, just to
  # mention one example.
  #
  #   @my = "no"
  #   path_to "this", "is", @my, "path"
  #
  # The constructed path will look like this:
  #
  #   /this/is/no/path
  #
  # It just puts together the arguments given to it.
  #
  # == Sessions
  #
  # Usually very important in the development of websites are sessions. There is some
  # basic support for it in webink, that will make certain bits easier. For more information
  # have a look at the blog-demo.
  #
  # Each controller usually expects cookies to work, if you handle sessions via cgi.
  # Whenever cookies do not work, or you do not intend to use them in the first place,
  # path_to and link_to watch out for the instance variables @session_key and @session_id
  # which are added via GET to the path/hyperlink, that they construct. Therefore the
  # tools should not be used for external linking. The dispatcher automatically filters
  # the GET session_id when using POST and adds it to the cgi.params, so sessions can
  # be used confortably.
  #
  # Per default, the @session_key should be "_session_id" as specified in the cgi/session
  # library from ruby core, but the controller offers some freedom, in case you may want
  # a different key name for some reason.
  #
  # 
  #
  class Controller
    
    # Constructor
    # 
    # Creates a new controller of the derived class. params are the globals set
    # by the dispatcher, and include keys like: :get, :post and :config. Also the
    # matched routes are put there, :controller, :module and any parameters like
    # :id or :page that were retrieved from the routes.
    # [param params:] Hash of Symbol => Objects
    def initialize(params)
      @params = params
    end
    
    # Instance method
    # 
    # Render a template or a partial that is located in the ./views/ folder of the
    # project. Subfolders are allowed to be specified. All instance variables are
    # accessible from within the template, as are any instance methods.
    # [param args:] Hash of arguments
    # [returns:] interpreted erb instance or nil
    def render(args)
      args[:locals] = Array.new if not args[:locals]
      template = nil
      if args[:template]
        template = File.open "./views/#{args[:template]}.html.erb", "r"
        erb = ERB.new template.readlines * "\n"
        template.close
        puts @params[:cgi].header
        erb.run self.getBinding(args[:locals])
      elsif args[:partial]
        template = File.open "./views/#{(File.dirname(args[:partial]) != ".") ? "#{File.dirname(args[:partial])}/" : ""}_#{File.basename(args[:partial])}.html.erb", "r"
        erb = ERB.new template.readlines * "\n"
        template.close
        if not args[:standalone]
          erb.result self.getBinding(args[:locals])
        else
          puts @params[:cgi].header
          erb.run self.getBinding(args[:locals])
        end
      else
        nil
      end
    end
    
    # Instance method
    # 
    # Redirect to a controller and module. The new controller will
    # be instanciated with a copy of the current params.
    # [param args:] Hash of arguments
    # [returns:] interpreted erb instance or nil
    def redirect_to(args)
      p = Hash.new
      @params.each do |k,v|
        p[k] = v
      end
      args.each do |k,v|
        p[k] = v
      end
      if p[:controller] and p[:module]
        controller = (Ink::Controller.verify p[:controller]).new p
        (controller.verify p[:module]).call
      else
        nil
      end
    end
    
    # Instance method
    #
    # Creates a dynamic hyperlink
    # First argument is the name, then follow the pieces that are imploded by
    # a /, followed by hashes, that become attributes. It adds the @session_key
    # and @session_id if they are set.
    # Convenience method
    # [param args:] Array of Strings and Hashes
    # [returns:] Hyperlink
    def link_to(*args)
      raise ArgumentError.new("Expects an array.") if not args.instance_of? Array and args.length < 2
      href = "#{@params[:root]}#{(@params[:root][@params[:root].length-1].chr == "/") ? "" : "/"}" if @params[:root].length > 0
      href = "/" if @params[:root].length == 0
      a = "<a "
      name = args[0]
      for i in 1...args.length
        arg = args[i]
        if not arg.instance_of? Hash
          href += "#{arg}/"
        else
          arg.each do |k,v|
            a += "#{k}=\"#{v}\" "
          end
        end
      end
      href += "?#{@session_key}=#{@session_id}" if @session_id and @session_key
      "#{a}href=\"#{href}\">#{name}</a>"
    end
    
    # Instance method
    #
    # Creates a dynamic path
    # The array pieces are imploded by a /. It adds the @session_key
    # and @session_id if they are set.
    # Convenience method
    # [param args:] Array of Strings or String
    # [returns:] path
    def path_to(*args)
      href = "#{@params[:root]}#{(@params[:root][@params[:root].length-1].chr == "/") ? "" : "/"}" if @params[:root].length > 0
      href = "/" if @params[:root].length == 0
      
      if args.is_a? Array
        for i in 0...args.length
          arg = args[i]
          href += "#{arg}/"
        end
      else
        href += "#{args}/"
      end
      href += "?#{@session_key}=#{@session_id}" if @session_id and @session_key
      href
    end
    
    # Instance method
    # 
    # Retrieve the current binding of the instance.
    # [param locals:] an Array of data for the template
    # [returns:] current binding
    def getBinding(locals)
      binding
    end
    
    # Class method
    # 
    # Retrieve the class of the name controller, that can be instanciated
    # by using new. Raises a NameError.
    # [param controller:] Controller name string
    # [returns:] class or nil
    def self.verify(controller)
      if not Module.const_defined? controller.capitalize
        if File.exists? "./controllers/#{controller}.rb"
          load "./controllers/#{controller}.rb"
        else
          raise NameError.new("Controller not found.")
        end
      end
      ((Module.const_get controller.capitalize).is_a? Class) ? (Module.const_get controller.capitalize) : (raise NameError.new("Controller not found."))
    end
    
    # Instance method
    # 
    # Retrieve the method of name mod, that can be called by using the
    # call method. Raises a NameError.
    # [param mod:] Method name string
    # [returns:] method or nil
    def verify(mod)
      self.method(mod)
    end
    
  end
  
end
