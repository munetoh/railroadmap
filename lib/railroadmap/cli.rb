#= CLI of railroadmap
#Authors:: Seiji Munetoh
#Copyright:: Copyright(C) Seiji Munetoh, 2011-2012. All rights reserved.
#License:: MIT
#
#=== History
#
#* 2011-05-03 Munetoh initial code
#* 2012-05-09 Munetoh update


require 'optparse'

# Logging
require 'logger'
$log = Logger.new(STDOUT)
$log.level = Logger::ERROR


require 'rails/abstraction'
require 'rails/route'
require 'rails/root'


module Railroadmap
  class CLI
    def self.execute(stdout, arguments=[])
      # Global variables
      $verbose = 0
      #$force = false
      
      $use_devise = false
      # NOTE: the option -p/--path= is given as an example, and should be replaced in your application.

      #
      # Check Option
      #
      lastarg = nil
      options = {
        :path     => '~',
        :initonly => false,
        :tracefile => nil,
        :graphviz => false,
        :force => false,
      }
      mandatory_options = %w(  )
      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          Usage: #{File.basename($0)} [options] command
          Commands:
            init      initialize
            modelgen  generate model (default)
            
          Options:
        BANNER
        opts.separator ""
        opts.on("-i", "--initonly",
                "Initialize only") { options[:initonly] = true }
        opts.on("-g", "--graphviz",
                "Plot FSM in PNG.") { options[:graphviz] = true }
        #opts.on("-G", "--graphvizdot",
        #        "FSM in DOT.") { options[:graphvizdot] = true }
        opts.on("-B", "--bmodel",
                "FSM in B model.") { options[:bmodel] = true }
        opts.on("-V", "--verbose",
                "Verbose.") { $verbose =  $verbose + 1 }
        opts.on("-v", "--version",
                "Version.") { 
                  stdout.puts "Version #{VERSION}"
                  stdout.puts opts; 
                  exit  }
        opts.on("-y", "--yesall",
                "Yes all.") { options[:force] = true }
        opts.on("-h", "--help",
                "Show this help message.") { stdout.puts opts; exit }
        opts.parse!(arguments)
        lastarg = arguments
        if mandatory_options && mandatory_options.find { |option| options[option.to_sym].nil? }
          stdout.puts opts; exit
        end
      end

      # Command check
      if lastarg[0] == nil then
        command = 'modelgen'
      elsif lastarg[0] == 'modelgen' then
         command = lastarg[0]
      elsif lastarg[0] == 'init' then
         command = lastarg[0]
      else
         # bad command?
        stdout.puts "bad command #{lastarg[0]}"
        exit
      end


      # Verbose
      #   -v     INFO
      #   -v -v  DEBUG
      case $verbose
      when 1
        $log.level = Logger::INFO
      when 2
        $log.level = Logger::DEBUG
      end

      # Setup dir and files
      approot_dir = Dir.pwd
      railroadmap_dir  = approot_dir + '/railroadmap'
      config_req       = approot_dir + '/railroadmap/config'
      config_file      = approot_dir + '/railroadmap/config.rb'
      abstraction_req  = approot_dir + '/railroadmap/abstraction'
      abstraction_file = approot_dir + '/railroadmap/abstraction.rb'
      $log.info( "verbose              : #{$verbose}")
      $log.info( "application dir      : #{approot_dir}")
      $log.info( "config file          : #{config_file}")
      $log.info( "abstraction map file : #{abstraction_file}")


      # Load application settings/anotation for RailroadMap
      # if missing create a template


      
      begin
        require config_req
        $log.debug( "loaded existing config file")
      rescue LoadError => e
        if options[:force] then
          ans = 'y'
        else
          puts "Configulation file (#{config_file}) is missing. create initial file? [Y/n]"
          ans = gets.chomp.downcase
        end
        
        if ans == 'y' then
          # create
          if File.exists?(railroadmap_dir) == false then
            Dir::mkdir(railroadmap_dir)
          end
          
          # Check application routes
          ard = Rails::Root.new
          root_list = ard.getRootDirsFromGems
          $log.debug "Show root list"
          if $log.debug? then
            pp root_list
          end
          
          open(config_file, "w") {|f| 
            f.write "# RailroadMap config file\n"
            if root_list != nil then
              # List
              f.write "\n"
              f.write "# Application root paths\n"
              f.write "$approot_list = [\n"
              root_list.each do |path|
                f.write "  '#{path}',\n"
              end
              f.write "]\n"
            end
            
            f.write "\n"
            f.write "# Application uses Devise\n"
            if $use_devise == true
              f.write "$use_devise = true\n"
            else
              f.write "$use_devise = false\n"
            end
            
            f.write "# Display transition from layout (BSD is getting busy)\n"
            f.write "$bsd_display_layout = false\n"
            f.write "# EOF\n"
          }
          
          require config_req
          $log.debug( "loaded NEW config file")
        else
          exit
        end  # if
      end
      
      # 
      begin
        require abstraction_req
        $log.debug( "loaded existing map file")
      rescue LoadError => e
        if options[:force] then
          ans = 'y'
        else
          puts "Abstraction map file (#{abstraction_file}) is missing. create initial file? [Y/n]"
          ans = gets.chomp.downcase
        end
        
        if ans == 'y' then
          # create
          if File.exists?(railroadmap_dir) == false then
            Dir::mkdir(railroadmap_dir)
          end
          # Check the route table
          # Check Routings
          r = Rails::Route.new
          route_map = r.getRoutes(approot_dir)
          $log.debug "Show route table"
          if $log.debug? then
            pp route_map
          end
          
          
          amap = Abstraction::Map.new
          amap.setRoutes(route_map)
          amap.newMap(abstraction_file)
          
          require abstraction_req
          $log.debug( "loaded NEW annotation file")
        else
          exit
        end
      end

      if options[:initonly] then
        # Exit
        puts "init done"
        exit
      end
 
      # Parse the application
      a = Abstraction::MVC.new($approot_list)
      a.load
      
      # Add Variables, CSRF, Devise
      # CSRF
      # puts "CSRF #{$protect_from_forgery}"
      if $protect_from_forgery
        require 'rails/csrf'
        $csrf = Rails::CSRF.new
        $csrf.add_variable()
      end
      # Devise
      if $use_devise
        # add abstracted variables for devise authentication
        require 'rails/devise'
        $devise = Rails::Devise.new
        $devise.add_variable() 
      end
      
      
      # Add transitions
      if $list_additional_transition != nil then
        p = Abstraction::Parser::AstParser.new
        $list_additional_transition.each do |t|
          p.add_transition(t[0], t[1], t[2], nil, nil, nil)
          $log.info "Added transition #{t[0]}, #{t[1]} -> #{t[2]}"
        end
      end
      
      # Log - before abstraction
      $log.info "Show application stat at the first scan"
      if $log.info? then
        a.print_stat
      end

      # Ruby code -> Abstracted expression
      a.path2id = $path2id
      a.set_variable_abstmap($map_variable)
      a.set_guard_abstmap($map_guard)
      a.set_guard_abstmap_by_block($map_guard_by_block)
      a.set_action_abstmap($map_action)
      
      
      # refine block, guard/action  Ruby => Abst
      a.complete_block
      
      # refine transition
      a.complete_transition

      # Log - after abstraction
      $log.info "Show application stat after the abstraction"
      if $log.info? then
        a.print_stat
      end

      # Generate outputs, HTML, PNG, B
      # Default output is HTML
      h = Abstraction::Output::Html5.new
      h.html('./railroadmap', nil)

      # PNG by Graphviz.  Heavy:-(
      if options[:graphviz] then
        a.graphviz('./railroadmap')
      end
      # DOY by Graphviz
      #if options[:graphvizdot] then
      #  s.outputGraphvizDot("./coverage")  
      #end
      
      # B model
      if options[:bmodel] then 
        # B method
        # probcli railroadmap/railroadmap.mch -c
        # prob railroadmap/railroadmap.mch
        b = Abstraction::Output::Bmethod.new
        b.output('./railroadmap')
      end
      
      $log.debug( "done")
    end
  end  # class CLI
end  # module railroadmap
