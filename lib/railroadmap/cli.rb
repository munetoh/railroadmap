# -*- coding: UTF-8 -*-
# = CLI of railroadmap
# Authors:: Seiji Munetoh
# Copyright:: Copyright(C) Seiji Munetoh, 2011-2013. All rights reserved.
# License:: MIT
#

require 'optparse'
require 'json'

# Logging
require 'logger'
$log = Logger.new(STDOUT)
$log.level = Logger::ERROR
$log.formatter = proc do |severity, datetime, progname, msg|
  if severity == 'ERROR' || severity == 'INFO' || severity == 'DEBUG'
    position = caller.at(4).sub(%r{.*/}, '').sub(%r{:in\s.*}, '')
    "#{severity} #{position} #{msg}\n"
  else
    "#{severity} #{msg}\n"
  end
end

require 'railroadmap/warning.rb'
require 'railroadmap/errors.rb'
require 'railroadmap/security-assurance-model.rb'
# require 'railroadmap/rails/abstraction/output/html'
# require 'railroadmap/rails/abstraction/output/table'

require 'railroadmap/map'
require 'railroadmap/dashboard'
require 'railroadmap/config-file'

require 'railroadmap/rails/abstraction'
require 'railroadmap/rails/route'

# Security features
require 'railroadmap/rails/csrf'
require 'railroadmap/rails/xss'
require 'railroadmap/rails/pdp'

require 'railroadmap/rails/requirement'
require 'railroadmap/rails/security-check'
require 'railroadmap/rails/cucumber'

# DEBUG w/ Tracer
require 'tracer'
# Tracer.on

module Railroadmap
  # Commandline I/F
  class CLI
    # run
    def self.execute(stdout, arguments = [])
      # Global variables
      $verbose = 0
      $robust = false
      $step_count = 0

      # Check Option
      lastarg = nil
      options = {
        path:      '~',
        initonly:  false,
        tracefile: nil,
        graphviz:  false,
        force:     false,
      }

      mandatory_options = %w(  )
      OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /, '')
          Usage: #{File.basename($PROGRAM_NAME)} COMMAND [options]
          Commands:
            init         initialize
            genmodel     generate navigation and dataflow model
            sectest      run static security test (default)

          Options:
        BANNER

        opts.separator ""
        opts.on("-V", "--verbose",
                "Verbose.") { $verbose =  $verbose + 1 }
        opts.on("-v", "--version",
                "Version.") do
          stdout.puts "RailroadMap Version #{RailroadMap::VERSION}"
          exit
        end
        opts.on("-y", "--yesall",
                "Yes all.") { options[:force] = true }
        opts.on("-h", "--help",
                "Show this help message.") do
          stdout.puts opts
          exit
        end
        opts.parse!(arguments)
        lastarg = arguments
        if mandatory_options && mandatory_options.find { |option| options[option.to_sym].nil? }
          stdout.puts opts
          exit
        end
      end # parser

      # Global flag
      $generate_all_trans     = false  # Gen all trans initiated by filters

      # Command check
      if lastarg[0].nil?
        # no command => help
        execute(stdout, ["-h"])
        exit
      elsif lastarg[0] == 'init'
        options[:initonly] = true
      elsif lastarg[0] == 'routemap'
        options[:routemap] = true
      elsif lastarg[0] == 'genmodel'
        options[:navmodel]  = true
        options[:command]   = true # for DEBUG
        options[:smodel]    = true
        options[:dashboard] = true
      elsif lastarg[0] == 'sectest' # Run Static Test
        options[:navmodel]  = true
        options[:runsc]     = true
        options[:brakeman]  = true
        options[:smodel]    = true
        options[:genpdp]    = true
        options[:dashboard] = true
        options[:command]   = true  # for DEBUG
      else
         # bad command?
        stdout.puts "bad command #{lastarg[0]}"
        exit
      end

      # Verbose
      #  1: -V          Verbose
      #  2: -V -V       INFO       Check paser
      #  3: -V -V -V    DEBUG      All debug msg
      #  4: -V -V -V -V Robust     raise if error
      case $verbose
      when 2
        $log.level = Logger::INFO
      when 3
        $log.level = Logger::DEBUG
      when 4
        $log.level = Logger::DEBUG
        $robust = true
      end

      # Warnings (weaknesses)
      $warning ||= Warning.new

      # Errors (bug of this tool)
      $errors ||= Errors.new

      # Setup dir and files
      $approot_dir = Dir.pwd
      railroadmap_dir   = $approot_dir + '/railroadmap'
      config_req        = $approot_dir + '/railroadmap/config'
      config_file       = $approot_dir + '/railroadmap/config.rb'
      abstraction_req   = $approot_dir + '/railroadmap/abstraction'
      abstraction_file  = $approot_dir + '/railroadmap/abstraction.rb'
      abstraction_fix   = $approot_dir + '/railroadmap/abstraction_fix'

      requirements_req  = $approot_dir + '/railroadmap/requirements'
      requirements_file = $approot_dir + '/railroadmap/requirements.rb'
      # requirements_fix  = $approot_dir + '/railroadmap/requirements_fix'

      blankmap_file       = railroadmap_dir + '/blankmap.json'
      # blankmap_table_file = railroadmap_dir + '/blankmap_table.html'
      hazardmap_file      = railroadmap_dir + '/hazardmap.json'

      securitycheck_file  = railroadmap_dir + '/securitycheck.json'

      brakeman_file = $approot_dir + '/brakeman.json'  # TODO

      # stdout
      puts "RailroadMap version #{Railroadmap::VERSION} (alpha)"
      puts "(c) Seiji Munetoh"

      if $verbose > 0
        puts "  verbose              : #{$verbose}"
        puts "  robust mode          : #{$robust}"
        puts "  application dir      : #{$approot_dir}"
        puts "  config file          : #{config_file}"
        puts "  abstraction map file : #{abstraction_file}"
      end

      ##########################################################################
      # Step 0: Init tool
      #   Load application settings/anotation for RailroadMap
      #   if missing create a template
      ##########################################################################

      puts ""
      puts "Step #{$step_count}: Init/Load configulations"
      $step_count += 1

      #-------------------------------------------------------------------------
      # Load or Create railroadmap/config.rb
      begin
        require config_req
        $log.debug "loaded existing config file"
      rescue LoadError
        if options[:force]
          ans = 'y'
        else
          # ask
          puts "Configulation file (#{config_file}) is missing. create initial file? [Y/n]"
          ans = STDIN.gets
          ans = ans.chomp.downcase
        end  # if force

        if ans == 'y'
          # save
          $config = ConfigFile.new
          $config.new_config(railroadmap_dir, config_file)
          # load
          require config_req
          $log.debug "loaded NEW config file"
        else
          exit
        end  # if create
      end

      #-------------------------------------------------------------------------
      # Load/Create railroadmap/abstract.rb
      begin
        $authentication_module = nil
        $authorization_module = nil
        require abstraction_req
        $log.debug "loaded existing map file"
      rescue LoadError
        if options[:force]
          ans = 'y'
        else
          # ask
          puts "Abstraction map file (#{abstraction_file}) is missing. create initial file? [Y/n]"
          ans = $stdin.gets.chomp.downcase
        end

        if ans == 'y'
          # create
          Dir.mkdir(railroadmap_dir) if File.exists?(railroadmap_dir) == false

          # Get the route table
          r = Rails::Route.new
          raw_route_map = r.get_routes($approot_dir)

          # Save
          amap = Abstraction::Map.new
          # amap.set_raw_routes(raw_route_map)
          amap.raw_route_map = raw_route_map
          amap.save(abstraction_file)

          # Load again
          require abstraction_req
          $log.debug("loaded NEW annotation file")
        else
          exit
        end
      end

      # -----------------------------------------------------------------------
      if options[:initonly]
        # Exit here
        puts "init done"
        exit
      end

      # -----------------------------------------------------------------------
      # routemap (=rake routes)
      # Hash[domain] = [path, method, url]
      #
      if options[:routemap]
        r = Rails::Route.new
        begin
          raw_route_map = r.get_routes($approot_dir)
          $log.debug "Show route table"
        rescue => e
          p e
          $log.error "WORKAROUND: 'Could not find a JavaScript runtime.' => add the following gems to GemFile"
          puts "---"
          puts "gem 'execjs'"
          puts "gem 'therubyracer'"
          puts "---"
          raise "Fix GemFile"
        end
        puts "railroadmap/abstraction.rb"
        puts "---"

        am = Abstraction::Map.new
        am.set_raw_routes(raw_route_map)
        am.print
        puts "---"
      end

      ##########################################################################
      # Step 1: Parse the application -> Model
      ##########################################################################

      #-------------------------------------------------------------------------
      # Rails code -> Navigation model/FSM(states,transition)
      #                  -> Blankmap (in Json)
      #                  -> Table
      #                  -> Html?
      if options[:navmodel]
        # TODO: if exist => ask update or not, or check the force flag
        puts ""
        puts "Step #{$step_count}: Parse the application and generate a navigation model"
        $step_count += 1

        # $route_map => $path2id
        # add XXX_url, XXX_path, @XXXX
        # $path2id will be provided by railroadmap/abstract.rb
        $path2id ||= {}
        $route_map.each do |k, v|
          path = v[1]
          unless path.nil?
            id = "C_" + k
            $path2id[path] = id
            $path2id[path + '_url'] = id
            $path2id[path + '_path'] = id
            $path2id['@' + path] = id
          end
        end

        # Global variables
        $list_class = {}
        $list_global_filter = {}
        $asset_remediations = {}
        $abst_commands_local = {}

        $abst_transitions_count = 0
        $abst_dataflows_count = 0

        # Security functions
        $csrf = Rails::CSRF.new
        $xss  = Rails::XSS.new

        # Check authentication modules
        if $authentication.nil?
          $log.error "missing $authentication, e.g. railroadmap/config.rb, $authentication='devise' devise|custom|none"
        else
          if $authentication == 'devise'
            require 'railroadmap/rails/devise'
            $authentication_module = Rails::Devise.new
          elsif $authentication == 'authlogic'
            require 'railroadmap/rails/authlogic'
            $authentication_module = Rails::Authlogic.new
          elsif $authentication == 'custom'
            if $authentication_module.nil?
              $log.error " $authentication = 'custom' =>  please set $authentication_module (Abstraction::SecurityFunction) too"
            end
          else
            $log.error "unknown missing $authentication #{$authentication}"
          end
        end

        # Check authorization modules
        if $authorization.nil?
          $log.error "missing $authorization, e.g. railroadmap/config.rb, $authorization='cancan' cancan|custom|none"
        else
          if $authorization == 'cancan'
            require 'railroadmap/rails/cancan'
            $authorization_module = Rails::CanCan.new
          elsif $authorization == 'the_role'
            require 'railroadmap/rails/the-role'
            $authorization_module = Rails::TheRole.new
          elsif $authorization == 'custom'
            if $authorization_module.nil?
              $log.error " $authorization = 'custom' =>  please set $authorization_module (Rails::PDP) too"
            end
          elsif $authorization == 'none'
            # No auth
          else
            $log.error "unknown missing $authorization #{$authorization}"
          end
        end

        # load the MVC code
        unless $approot_list.nil?
          $log.error "20131007 config.rb format was changed. $approot_list => $approot_hash"
          $abst = Abstraction::MVC.new
          $abst.init_by_approot_list($approot_list)
        end

        unless $approot_hash.nil?
          $abst = Abstraction::MVC.new
          $abst.init_by_approot_hash($approot_hash)
        end

        fail "define $approot_hash in rairoadmap/config.rb" if $abst.nil?

        # Parse the MVC code
        $abst.load

        # [Manual] Add transitions
        # abstraction_fix
        if File.exist?(abstraction_fix + ".rb")
          require abstraction_fix
          # State
          unless $list_additional_state.nil?
            ast = Abstraction::Parser::AstParser.new
            $list_additional_state.each do |s|
              $log.error "Added state #{s[0]}, #{s[1]}"
              ast.add_state(s[0], s[1], 'nul')
            end
          end

          # Trans
          unless $list_additional_transition.nil?
            ast = Abstraction::Parser::AstParser.new
            $list_additional_transition.each do |t|
              $log.debug "Added transition #{t[0]}, #{t[1]} -> #{t[2]}"
              trans = ast.add_transition(t[0], t[1], t[2], nil, nil, nil)  # added by user
              trans.origin = 'manual'
              trans.comment = 'added by $list_additional_transition'
            end
            puts "    added #{$list_additional_transition.length} transitions of $list_additional_transition"
          end

          # Dataflow
          unless $list_additional_dataflow.nil?
            ast = Abstraction::Parser::AstParser.new
            $list_additional_dataflow.each do |df|
              $log.debug "Added dataflow #{df[0]}, #{df[1]} ---> #{df[2]}"
              df = ast.add_dataflow(df[0], df[1], nil, df[2], nil, abstraction_fix + ".rb")
              df.origin = 'manual'
              df.comment = 'added by $list_additional_dataflow'
            end
            puts "    added #{$list_additional_dataflow.length} transitions of $list_additional_dataflow"
          end
        end

        # Log - before abstraction
        $log.info "Show application stat at the first scan"
        $abst.print_stat if $log.info?

        # Ruby code -> Abstracted expression
        # check
        fail "set $path2id in #{abstraction_file}" if $path2id.nil?
        fail "set $map_variable in #{abstraction_file}" if $map_variable.nil?
        fail "set $map_guard in #{abstraction_file}" if $map_guard.nil?
        fail "set $map_guard_by_block in #{abstraction_file}" if $map_guard_by_block.nil?
        fail "set $map_action in #{abstraction_file}" if $map_action.nil?

        # Set
        $abst.path2id = $path2id
        $abst.set_variable_abstmap($map_variable)
        $abst.set_guard_abstmap($map_guard)
        $abst.set_guard_abstmap_by_block($map_guard_by_block)
        $abst.set_action_abstmap($map_action)

        # refine block, guard/action  Ruby => Abst
        $abst.complete_block
        # refine filter
        $abst.complete_filter
        # refine transition
        $abst.complete_transition

        puts "    states         : #{$abst_states.size}"
        if $generate_all_trans
          puts "    transitions    : #{$abst_transitions.size}  (before_filter: #{$filter_added_trans_count})"
          puts "      BF trans.    : #{$filter_added_trans_count} are added for TC gen"
        else
          puts "    transitions    : #{$abst_transitions.size}  (before_filter: #{$filter_added_trans_count} SKIPPED)"
          puts "      BF trans.    : #{$filter_added_trans_count} are not added for runsc"
        end

        #----------------------------------------------------------------------
        # load requirements
        puts ""
        puts "Step #{$step_count}: Load requirements (Policy injection)"
        $step_count += 1

        $req = Rails::Requirement.new
        $req.load(requirements_req, requirements_file)

        #-----------------------------------------------------------------------
        # generate Table in HTML

        if $warning.nil?
          print "\e[32m"  # green
          puts "    warnings       : 0"
        else
          size = $warning.size
          if size > 0
            print "\e[31m"  # red
            puts "    warnings       : #{size}"
          else
            print "\e[32m"  # green
            puts "    warnings       : #{size}"
          end
        end
        print "\e[0m" # reset
      end  # Blankmap

      #----------------------------------------------------------------------
      # generate Nav. model (Blankmap) in JSON
      if options[:savenavmodel]
        date = Time.now
        m = Map.new(date.to_s)
        m.states = $abst_states

        # TODO: rename to navmodel
        File.open(blankmap_file, 'w') do |f|
          f.write(JSON.pretty_generate(m))
        end
        puts "    Navigation model(blank map) (#{blankmap_file}) was generated"
      end

      #----------------------------------------------------------------------
      # Command / Filter list
      #
      if options[:command]
        if $verbose == 1
          # stdout
          puts ""
          puts "==== Command ========================================== count === providedby ======== type ===== subtype == SF? = trans?==="
          $abst_commands.each do |k, c|
            # set color
            if c.providedby != 'unknown' && c.count > 0
              print "\e[32m"  # green
            end
            if c.providedby == 'unknown'
              print "\e[31m"  # red
            end
            # puts "#{k.ljust(50)} #{c.count.to_s.rjust(10)}  #{c.providedby.rjust(13)} #{c.type.rjust(13)} #{c.subtype.rjust(13)} #{c.is_sf.to_s.rjust(6)}  #{c.has_trans.to_s.rjust(6)}"
            puts c.filenames if c.providedby == 'unknown'
            print "\e[0m" # reset color
          end
          puts ""
        end

        if $unknown_command > 0
          print "\e[31m"  # red
          puts "    unknown command: #{$unknown_command}"
          puts ""
          puts "railroadmap/abstraction.rb"
          puts "---"
          puts "$local_commands = {"
          $abst_commands.each do |k, c|
            if c.status == 'unknown'
              aclk = $abst_commands_local[k]
              if aclk.nil?
                puts "   '#{k}' => {"
                puts "     type:'#{c.type}'"
                puts "   },"
              else
                # app command
                puts "   # #{aclk}"
                puts "   '#{k}' => {"
                puts "     type:'#{c.type}',"
                puts "     providedby: 'app'"
                puts "   },"
              end
            end
          end
          puts "}"
          puts "---"
          print "\e[0m" # reset
          puts""
        else
          puts "    unknown command: 0"
        end
      end

      #----------------------------------------------------------------------
      # Class list
      #                                                  has_ch has_pa
      # $list_class[name] = [pclass, 'model', ruby_code, false, false]
      if options[:class]
        puts "    unknown class  : #{$list_class.size}"

        # Tree?
        $list_class.each do |k, v|
          parent = $list_class[v[0]]
          unless arent.nil?
            v[4] = true
            parent[3] = true
          end
        end

        # dump
        puts ""
        $list_class.each do |k, v|
          if v[3] == false
            # no ch
            out = "    #{k} < #{v[0]}"
            c = v[0]
            until $list_class[c].nil?
              v2 = $list_class[c]
              out += " < #{v2[0]}"
              c = v2[0]
            end
            puts out
          end
        end
        puts ""
      end

      ##########################################################################
      # Static : Security Check on NavModel
      #  * check compleatness of Access control implementation
      #
      if options[:runsc]
        #-----------------------------------------------------------------------
        # generate security check report in JSON (Brakeman format)
        #
        puts ""
        puts "Step #{$step_count}: Run security check (access control) againt navigation model (1st check)"
        $step_count += 1

        sc = Rails::SecurityCheck.new
        sc.save_json(securitycheck_file)
        puts "    Security check(#{securitycheck_file}) was generated"
        $xss.trace_raw
        $warning.update_file2($approot_dir, '.')

        if $warning.count > 0
          # show Policy map
          # railroadmap/rails/requirement.rb
          $req.print_policy_assignment
        end
      end

      ##########################################################################
      # Step 2a: Place a flag on fragile state.
      #
      # Brakeman reports --(json)-+
      #                           |
      #                           V
      #                       blank map  -> hazard map (Abuse model)
      #
      #   $ railroadmap blankmap   => blankmap.json
      #   $ brakeman -o brakeman.json
      #   $ railroadmap brakeman   => hazardmap.json
      #
      # TODO: move to lib/brakeman.rb

      if options[:brakeman]
        puts ""
        puts "    load brakeman report (#{brakeman_file})"
        # TODO: check blankmap is ready or not
        brakeman_hash = nil
        begin
          open(brakeman_file, 'r') { |fp| brakeman_hash = JSON.parse(fp.read) }

          # scan_info = brakeman_hash['scan_info']
          warnings = brakeman_hash['warnings']
          errors = brakeman_hash['errors']
          # to Dashboard
          $brakeman_warnings = warnings

          if warnings.size > 0
            print "\e[31m"  # red
            puts "    warnings : #{warnings.size}"
            print "\e[0m" # reset
          else
            print "\e[32m"  # green
            puts "    warnings : #{warnings.size}"
            print "\e[0m" # reset
          end

          if errors.size > 0
            print "\e[31m"  # red
            puts "    errors   : #{errors.size}"
            print "\e[0m" # reset
          else
            print "\e[32m"  # green
            puts "    errors   : #{errors.size}"
            print "\e[0m" # reset
          end

          hit_state_count = 0
          id = 0
          warnings.each do |w|
            # copy
            type    = w['warning_type']
            message = w['message']
            file    = w['file']
            line    = w['line']

            # add attribute to brakeman warning
            w['id'] = id
            id += 1
            w['hit_state'] = ''
            w['hit_variable'] = ''
            # shorten filename, remove $approot_dir
            w['file2'] = file.sub($approot_dir, '.')

            if $verbose == 1
              puts "    id       : #{id}"
              puts "    type    : #{type}"
              puts "    message : #{message}"
            end

            # TODO: controller has multiple def (=states) => use line# to identify the exact state.
            # TODO: use hash to fined states?
            hit_state = nil
            $abst_states.each do |k, state|
              state.filename.each do |f|
                if f == file
                  if state.start_linenum < line
                    # last hit is the state we are looking for.
                    hit_state = state
                  end
                end
              end
            end
            unless hit_state.nil?
              # Set flag to the state
              mark = Abstraction::Mark.new('brakeman')
              mark.brakeman(type, message, line)
              hit_state.add_mark(mark)
              # Update attribute to brakeman warning
              w['hit_state'] = hit_state.id
              hit_state_count += 1
            end
          end
          puts "    Total #{hit_state_count} State Hits"
        rescue
          $log.error "Brakeman"
          print "\e[31m"  # red
          puts " run brakeman "
          puts " $ brakeman -f json > brakeman.json"
          print "\e[0m" # reset
        end

        # Save to JSON
        date = Time.now
        m = Map.new(date.to_s)
        m.states = $abst_states

        File.open(hazardmap_file, 'w') do |f|
          f.write(JSON.pretty_generate(m))
        end
        puts "    Hazard map(#{hazardmap_file}) was generated"
      end

      # Static Analysis Summary => Security Assuarance Model
      if options[:smodel]
        puts ""
        puts "    Security assurance model (2nd check)"
        $smodel = SecurityAssuranceModel.new
      end

      ##########################################################################
      # Generate PDP
      if options[:genpdp]
        #-----------------------------------------------------------------------
        # generate PDP
        puts ""
        puts "Step #{$step_count}: Run security check (access control) againt navigation model (1st check)"
        $step_count += 1

        $authorization_module.generate_pdp(nil) unless $authorization_module.nil?
      end

      #-----------------------------------------------------------------------
      # Dashboard (New version, simplecov looks)
      # files
      #   lib/dashboard.rb
      #   views/layout.erb
      if options[:dashboard]
        puts ""
        puts "Step #{$step_count}: Generate dashboard (HTML)"
        $step_count += 1

        # lib/dashboard.rb
        dashboard = Dashboard.new
        dashboard.format($smodel)

        # TODO: select by OS and installed browser
        puts "     open result in HTML"
        puts "     OSX$ open -a Safari railroadmap/index.html"
        puts "  Ubuntu$ chromium-browser railroadmap/index.html"
      end
    end

  end  # class CLI
end  # module railroadmap
