# get application route table

module Rails
class Route
  def initialize
  end

  def getRoutes(xDir)

    # TODO check rails version
    # NG v = Rails::VERSION::STRING

    getRoutesV3_0(xDir)
    #getRoutesV3_1(xDir)
  end
  
  

  #
  # Rails v3.0.X
  #  http://stackoverflow.com/questions/3986997/is-there-a-way-to-make-rake-routes-look-better
  def getRoutesV3_0(xDir)
    require(File.join(xDir, 'config', 'boot'))
    require(File.join(xDir, 'config', 'environment'))

    $log.debug("Getting RoR v3.0 application route table at #{xDir}")

    all_routes = ENV['CONTROLLER'] ? ActionController::Routing::Routes.routes.select { |route|
      route.defaults[:controller] == ENV['CONTROLLER']
    } :  ActionController::Routing::Routes.routes

    routes = all_routes.collect do |route|
      reqs = route.requirements.empty? ? "" : route.requirements.inspect
      {:name => route.name, :verb => route.verb, :path => route.path, :reqs => reqs}
    end

    route2map(routes)

    #ac = [["",""]]
    #routes.each do |r|
    #  if r[:name] == nil then
    #    # TODO no name, 
    #    #puts "name=nil routes exist"
    #  elsif r[:name] == "root" then
    #    # verb is nil
    #    a = r[:reqs].scan(/:action=>"(\w*)"/)
    #    c = r[:reqs].scan(/:controller=>"(\w*)"/)
    #    s = @fsm.addControllerSubvertex(r[:name], "TBD", r[:path], c[0][0], a[0][0], "routes", nil)
    #    #s.path = "root"
    #    s.routed = true
    #  elsif r[:verb] == nil then
    #    # SKIP 
    #    myDebug("route #{r} - SKIP")
    #  else
    #    a = r[:reqs].scan(/:action=>"(\w*)"/)
    #    c = r[:reqs].scan(/:controller=>"(.*)"/)   # hoge/hoge
    #    #puts c
    #    s = @fsm.addControllerSubvertex(r[:name], r[:verb], r[:path], c[0][0], a[0][0], "routes", nil)
    #    s.routed = true
    #  end
    #end

    route2map(routes)
  end

  #
  # Rails v3.1.X, also V3.0?
  # vendor/bundle/ruby/1.9.1/gems/railties-3.1.3/lib/rails/tasks/routes.rake
  #
  #
  def getRoutesV3_1(xDir)
    # load application conf
    require(File.join(xDir, 'config', 'boot'))
    require(File.join(xDir, 'config', 'environment'))

    $log.debug("Getting RoR v3.1 application route table at #{xDir}")

    Rails.application.reload_routes!
    all_routes = Rails.application.routes.routes
        
    if ENV['CONTROLLER']
      all_routes = all_routes.select{ |route| route.defaults[:controller] == ENV['CONTROLLER'] }
    end
  
    routes = all_routes.collect do |route|
      reqs = route.requirements.empty? ? "" : route.requirements.inspect
      {:name => route.name, :verb => route.verb, :path => route.path, :reqs => reqs}
    end

    route2map(routes)
  end


  # Route table => hash map
  def route2map(routes)
    # Map
    #   pathname => [controler, action, GET|POST, path]
    map = Hash.new
    
    ac = [["",""]]
    routes.each do |r|
      if r[:name] == nil then
        # TODO no name, 
      elsif r[:name] == "root" then
        # verb is nil
        a = r[:reqs].scan(/:action=>"(\w+)"/)
        c = r[:reqs].scan(/:controller=>"(\w+)"/)
        map[r[:name]] = [c[0][0], a[0][0],'ROOT',r[:path]]
      elsif r[:verb] == nil then
        # SKIP 
        $log.debug("route #{r} - SKIP")
      else
        a = r[:reqs].scan(/:action=>"([a-z_]+)"/)
        c = r[:reqs].scan(/:controller=>"([a-z_\/]+)"/)   # hoge/hoge
        map[r[:name]] = [c[0][0], a[0][0], r[:verb],r[:path]]
      end
    end
    
    # puts "SM DEBUG 3.1 done"
    map
  end
end
end