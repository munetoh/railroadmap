# -*- coding: UTF-8 -*-
# get application route table

module Rails
  # Route table
  class Route
    def initialize
    end

    def get_routes(xDir)
      puts "getRoutes"
      # TODO: check rails version
      # NG v = Rails::VERSION::STRING

      #
      # Rails version is checked by init, railroadmap -i
      # Then recorded in railroadmap/config.rb file
      #
      if $rails_version.nil?
        $log.error "set $rails_version in railroadmap/config.rb"
        $rails_version = "3.0.0"
        fail "$rails_version is missing"
      end

      v =  Gem::Version.create($rails_version)
      puts "    rails version : #{v}"

      if v >= Gem::Version.create('3.1.0')
        get_routes_v31(xDir)
      elsif v >= Gem::Version.create('3.0.0')
        get_routes_v30(xDir)
      else
        fail "Rails #{$rails_version} is not supported yet"
      end
    end

    #
    # Rails v3.0.X
    # http://stackoverflow.com/questions/3986997/is-there-a-way-to-make-rake-routes-look-better
    def get_routes_v30(xDir)
      require(File.join(xDir, 'config', 'boot'))
      require(File.join(xDir, 'config', 'environment'))

      $log.debug("Getting RoR v3.0 application route table at #{xDir}")

      all_routes = ENV['CONTROLLER'] ? ActionController::Routing::Routes.routes.select { |route|
        route.defaults[:controller] == ENV['CONTROLLER']
      } : ActionController::Routing::Routes.routes

      routes = all_routes.collect do |route|
        reqs = route.requirements.empty? ? "" : route.requirements
        {
          name: route.name,
          verb: route.verb,
          path: route.path,
          reqs: reqs
        }
      end

      $new_routemap = false # TODO
      routes
    end

    #
    # Rails v3.1.X, also V3.0?
    # vendor/bundle/ruby/1.9.1/gems/railties-3.1.3/lib/rails/tasks/routes.rake
    #
    def get_routes_v31(xDir)
      # load application conf
      require(File.join(xDir, 'config', 'boot'))
      require(File.join(xDir, 'config', 'environment'))

      $log.debug("Getting RoR v3.1 application route table at #{xDir}")

      Rails.application.reload_routes!
      all_routes = Rails.application.routes.routes
      if ENV['CONTROLLER']
        all_routes = all_routes.select { |route| route.defaults[:controller] == ENV['CONTROLLER'] }
      end

      routes = all_routes.collect do |route|
        reqs = route.requirements.empty? ? "" : route.requirements.inspect
        {
          name:     route.name,
          verb:     route.verb,
          path:     route.path,
          reqs:     reqs,
          app:      route.app,
          defaults: route.defaults
        }
      end

      $new_routemap = true  # TODO: ?
      routes
    end

    # Route table => hash map
    # 2013-04-11
    #
    def route2map(routes)
      # Map
      #   pathname => [controler, action, GET|POST, path]
      map = {}
      ac  = [["", ""]]
      routes.each do |r|
        if r[:name].nil?
          # TODO: no name
        elsif r[:name] == "root"
          # verb is nil
          a = r[:reqs].scan(/:action=>"(\w+)"/)
          c = r[:reqs].scan(/:controller=>"(\w+)"/)
          map[r[:name]] = [c[0][0], a[0][0], 'ROOT', r[:path]]
        elsif r[:verb].nil?
          $log.debug("route #{r} - SKIP")
        elsif r[:verb] == ""
          # SKIP
          $log.error("route #{r} - SKIP")
          # 2013-04-11 Nancy => netzke  /netzke/:action(.:format)  {:controller=>"netzke"}
        else
          a = r[:reqs].scan(/:action=>"([a-z_]+)"/)
          c = r[:reqs].scan(/:controller=>"([a-z_\/]+)"/)   # hoge/hoge
          map[r[:name]] = [c[0][0], a[0][0], r[:verb], r[:path]]
        end
      end
      map
    end
  end
end
