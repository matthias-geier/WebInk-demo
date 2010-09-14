module Ink

  # = Beauty class
  #
  # This class provides a set of tools for loading config and init scripts
  # as well as the route-matching. It makes the dispatcher code much more
  # beautiful, hence the name.
  # 
  # 
  #
  class Beauty
    
    # Class method
    # 
    # Attempts to load the init file of the project or raises a LoadError.
    # [param script:] Project folder path
    # [returns:] valid init file path
    def self.load_init(script)
      script = "#{File.dirname(script)}/init"
      script = "#{script}.rb" if not File.exist? script
      raise LoadError.new("Init not found.") if not File.exist? script
      script
    end
    
    # Class method
    # 
    # Attempts to load the config file of the project or raises a LoadError.
    # Once loaded, the config is evaluated and can raise a RuntimeError, or
    # it is returned
    # [param script:] Project folder path
    # [returns:] a valid config
    def self.load_config(script)
      config = "#{File.dirname(script)}/config"
      config = "#{config}.rb" if not File.exist? config
      raise LoadError.new("Config not found.") if not File.exist? config
      fhandle = Mmap.new(config, "r")
      config = eval fhandle
      fhandle.munmap
      raise RuntimeError.new("Config error.") if not config.instance_of? Hash
      config
    end
    
    # Class method
    # 
    # Attempts to load the routes file of the project or raises a LoadError
    # [param script:] Project folder path
    # [returns:] valid routes file path
    def self.load_routes(script)
      routes = "#{File.dirname(script)}/routes"
      routes = "#{routes}.rb" if not File.exist? routes
      raise LoadError.new("Routes not found.") if not File.exist? routes
      routes
    end
    
    # Class method
    # 
    # Attempts to match the params onto the routes and return the results in
    # form of a Hash.
    # [param root:] Relative project folder path to the server document path
    # [param routes:] Array of Arrays: regex, Hash(Symbol => String)
    # [param params:] Requested string
    # [returns:] Hash of Symbol => String
    def self.routing(root, routes, params)
      match = { :root => root }
      routes.each do |entry|
        k = entry[0]
        v = entry[1]
        if params =~ k
          v.each do |sys,e|
            match[sys] = (e =~ /^\$\d+$/ and params =~ k and eval e) ? (eval e) : e
          end
          break
        end
      end
      match
    end
    
  end
  
end
