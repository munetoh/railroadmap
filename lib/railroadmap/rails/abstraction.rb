# -*- coding: UTF-8 -*-
# Rails app code => Navigation Model
#
require 'railroadmap/rails/abstraction/block'
require 'railroadmap/rails/abstraction/policy'
require 'railroadmap/rails/abstraction/state'
require 'railroadmap/rails/abstraction/transition'
require 'railroadmap/rails/abstraction/dataflow'
require 'railroadmap/rails/abstraction/variable'
require 'railroadmap/rails/abstraction/parser/ast'
require 'railroadmap/rails/abstraction/parser/model'
require 'railroadmap/rails/abstraction/parser/view'
require 'railroadmap/rails/abstraction/parser/controller'
# require 'railroadmap/rails/abstraction/output/html5'
# require 'railroadmap/rails/abstraction/output/bmethod'
# require 'railroadmap/rails/abstraction/output/cucumber'
require 'railroadmap/rails/abstraction/map'
require 'railroadmap/rails/abstraction/attack'
require 'railroadmap/rails/abstraction/command'
require 'railroadmap/rails/abstraction/filter'
require 'railroadmap/rails/abstraction/mark'
require 'railroadmap/rails/abstraction/security-function'

require 'railroadmap/rails/rails-commands'

require 'sorcerer'

# root of Abstraction
module Abstraction
  #############################################################################
  # Model-View-Controller class
  #
  class MVC < Abstraction::Parser::AstParser
    #
    # Initialize MVC abstraction variables
    #
    def initialize
      # TBD
      @path2id = nil
      @guard2abst = nil
      @action2abst = nil
      @commands = nil
    end
    attr_accessor :path2id, :guard2abst, :action2abst, :commands

    def init_by_approot_list(list)
      $log.error "obsolete "
      @basedirs = list
      @skipdirs = {}
      init
    end

    def init_by_approot_hash(hash)
      @basedirs = []
      @skipdirs = {}
      hash.each do |k, v|
        @basedirs << v[:dir]
        option = v[:option]
        if option.nil?
          # No option, parse all
        elsif option == 'except_views'
          dir = v[:dir] + "/app/views"
          @skipdirs[dir] = true
        else
          fail "Unknown railroadmap/config.rb option, #{option} "
        end
      end
      init
    end

    def init
      if @basedirs.nil?
        if $rspec_on
          $log.debug "Abstraction::MVC - UNIT TEST MODE"
        else
          fail "initialize fail. basedirs is nil"
        end
      else
        # global and flat
        # TODO: $abst_states => $abst.state
        $abst_states = {}
        $abst_transitions = {}
        $abst_variables = {}
        $abst_dataflows = {}

        # 2013-06-28 SM refine
        $unknown_command = 0
        $abst_commands = {}
        init_commands

        # TODO: delete
        # ruby => abstaction map
        $abstmap_variable = {}        # Variable id => name, type
        $abstmap_guard    = {}           # Ruby code   => Abstracted Guard Code
        $abstmap_guard_by_block = {}  # Ruby block  => Abstracted Guard Code
        $abstmap_action = {}          # Block id    => Abstracted Action Code
      end
      # Hash table to translate path to state ID
      @path2id = nil
      # Guard, Action to Abst
      @guard2abst = nil
      @action2abst = nil
    end

    #  Init Commands - Rails basic
    def init_commands
      # add crails commands, defined in rails_command.rb
      rc = Rails::Commands.new

      # add AA commands
      unless $authentication_module.nil?
        $authentication_module.add_commands
        # List
        list = $authentication_module.get_command_list
        add_command_list(list) unless list.nil?
      end

      unless $authorization_module.nil?
        $authorization_module.add_commands
        # List
        list = $authorization_module.get_command_list
        add_command_list(list) unless list.nil?
      end

      # add app local command
      unless $local_trans_commands.nil?
        $local_trans_commands.each do |k, v|
          c = add_trans_command(k, v[1])
          c.providedby = 'app'
        end
      end

      # Set user defined commands. application
      add_command_list($local_commands) unless $local_commands.nil?
    end

    def add_to_command_list(classobj)
      if $abst_commands[classobj.name].nil?
        $abst_commands[classobj.name] = classobj
      else
        # no def before
        fail "'#{classobj.name}' already exist"
      end
    end

    def add_to_unknwon_command_list(name, type)
      c = Abstraction::Command.new
      c.name = name
      c.type = type
      c.providedby = 'unknown'
      c.status = 'unknown'
      add_to_command_list(c)
      return c
    end

    #
    # Load
    #
    def load
      # TODO
      load_models
      load_views
      load_controllers
    end

    # Models
    #  schema
    #  app/models
    def load_models
      @basedirs.each do |basedir|
        # parse models
        $log.debug "load model at : #{basedir}"
        count = 0
        # load db schema
        Dir.glob("#{basedir}/db/schema.rb").each do |fn|
          $log.debug "load model schema : #{fn}"
          # parse
          begin
            s = Abstraction::Parser::ModelSchema.new
            s.load(fn)
          rescue => e
            p e
            pp e.backtrace # with raise
            raise "#{fn} fail"
          end
        end

        # load app Models app/models/A.rb
        dir =  basedir + "/app/models"
        Dir.glob("#{dir}/*.rb").each do |fn|
          $log.debug "load model file : #{fn}"
          # look up
          # model name
          m = File.basename(fn, ".rb")
          mn = 'M_' + m
          # parse
          begin
            s = Abstraction::Parser::Model.new
            s.load(mn, m, fn)
          rescue => e
            p e
            pp e.backtrace
            raise "load #{fn} was failed"
          end
          count += 1
        end

        # load app Models app/models/A/B.rb
        # Schema M_A_B
        Dir.glob("#{dir}/*/*.rb").each do |fn|  # TODO: is this happen?
          $log.debug "load model file : #{fn}"
          # look up
          # model name
          d2 = File.dirname(fn)
          model = File.basename(d2)
          model2 = File.basename(fn, ".rb")
          m = model + '_' + model2
          mn = 'M_' + m

          # parse
          begin
            s = Abstraction::Parser::Model.new
            s.load(mn, m, fn)
          rescue => e
            p e
            pp e.backtrace
            raise "load #{fn} was failed"
          end
          count += 1
        end
        # TODO: add Devise helper variables
        # if $devise == true # TODO: deprecated
        #   add_varaible('helper')
        # end
        # check
        if count == 0
          $log.debug "  no model"
        else
          $log.debug "  #{count} model files"
        end
      end
    end

    # Controllers
    def load_controllers
      @basedirs.each do |basedir|
        # parse models
        $log.debug "load controller at : #{basedir}"
        count = 0
        # load app Models app/models
        dir =  basedir + "/app/controllers"

        # 1st level
        Dir.glob("#{dir}/*.rb").each do |fn|
          $log.debug "load controller file : #{fn}"
          # model name
          model = File.basename(fn, "_controller.rb")
          model = ActiveSupport::Inflector.singularize(model)
          # Skip devise's base methods
          next if model == 'devise'
          # parse
          begin
            c = Abstraction::Parser::Controller.new
            c.load(model, fn)
          rescue => e
            p e
            pp e.backtrace
            raise "load_controllers failed,  file=#{fn}"
          end
          count += 1
        end # do

        # 2nd level
        Dir.glob("#{dir}/*/*.rb").each do |fn|  # TODO: is this happen?
          $log.debug "load controllers file : #{fn}"
          # model name
          d2 = File.dirname(fn)
          m1 = File.basename(d2)
          m2 = File.basename(fn, "_controller.rb")
          m3 = ActiveSupport::Inflector.singularize(m2)
          model = m1 + ':' + m3
          # Skip devise's unused functions
          # set by model/user.rb
          if $use_devise # TODO: deprecated
            next if m1 == 'devise' && $device_features[m3] == false
          end
          # parse
          begin
            c = Abstraction::Parser::Controller.new
            c.load(model, fn)
          rescue => e
            p e
            pp e.backtrace
            raise "#{fn} fail"
          end
          count += 1
        end
        if count == 0
          $log.debug "  no controller"
        else
          $log.debug "  #{count} controller files"
        end
        # TODO: 3rd?
      end # do
    end

    # Views
    # ERB -> Abstraction::View
    # TODO: HAML
    def load_views
      @basedirs.each do |basedir|
        # parse models
        $log.debug "load_views : #{basedir}"
        # load app Models app/models
        dir =  basedir + "/app/views"

        if @skipdirs[dir]
          # SKIP
        else
          # Load
          # Dir => model
          # ERB => action
          # _form => form  TODO
          Dir.entries(dir).map do |f|
            path = File.expand_path(f, dir)
            $log.debug  "   model #{f} #{path}"
            # singularize for model
            model = ActiveSupport::Inflector.singularize(f)
            # Skip devise's base methods
            if f == "."
              # SKIP this
            elsif f == ".."
              # SKIP parents
            else
              # Scan app/views/*/*.rb
              Dir.glob("#{path}/*.erb").each do |fn|
                $log.debug "load : #{fn}"
                # parse
                begin
                  v = Abstraction::Parser::View.new
                  v.load(model, fn)
                rescue => e
                  p e
                  pp e.backtrace
                  raise "#{fn} fail"
                end
              end

              Dir.glob("#{path}/*/*.erb").each do |fn|
                $log.debug "load : #{fn}"
                if fn =~ /\/(\w+)\/(\w+)\/(\w+).(\w+).erb/
                  m1 = Regexp.last_match[1] # $1
                  m2 = ActiveSupport::Inflector.singularize(Regexp.last_match[2]) # $2
                  a  = Regexp.last_match[3] # $3
                  t  = Regexp.last_match[4] # $4
                  model =  m1 + ':' + m2
                else
                  p fn
                  fail "ERROR cannot se the model name"
                end
                # Skip devise's unused functions
                # set by model/user.rb
                if $use_devise # TODO: deprecated
                  next if m1 == 'devise' && $device_features[m2] == false
                end
                $log.debug "load_views #{model} #{fn}"
                v = Abstraction::Parser::View.new
                v.load(model, fn)
              end

              # HAML
              Dir.glob("#{path}/*.haml").each do |fn|
                v = Abstraction::Parser::View.new
                v.load_haml(model, fn)
              end

              Dir.glob("#{path}/*/*.haml").each do |fn|
                v = Abstraction::Parser::View.new
                v.load_haml(model, fn)
              end
            end # f
          end # DIRs  map
        end  # skip
      end  # loop
    end

    ###########################################################################
    # Abstraction map
    # TODO:  remove. just use global variables by cli
    def set_variable_abstmap(map)
      map.each do |id, a|
        $abstmap_variable[id] = a
      end
    end

    # Ruby => Abst
    def set_guard_abstmap(map)
      map.each do |r, a|
        $abstmap_guard[r] = a
      end
    end

    # Block => abst
    def set_guard_abstmap_by_block(map)
      map.each do |r, a|
        $abstmap_guard_by_block[r] = a
      end
    end

    # Block => abst
    def set_action_abstmap(map)
      map.each do |id, a|
        $abstmap_action[id] = a
      end
    end

    ###########################################################################
    # Complete abstractions
    #  Block/Condition
    def complete_block
      $abst_states.each do |n, s|
        state = $abst_states[n]
        $log.debug "abstraction.complete_block  #{n}  #{state.filename}"
        s.complete_condition($abstmap_guard, $abstmap_guard_by_block) # @guard2abst)
      end
    end

    # Filter => Flags
    def complete_filter_set_flags(state, filter, type)
      add_trans = false
      if filter.type == 'filter'
        if filter.providedby == 'unknown'
          # SKIP unknown(=undef) filter
          $log.error "complete_filter() - state=#{n} filter=#{name}  #{fc.providedby}"
        else
          if type == 'on'
            # Abstruction
            if filter.sf_type == 'authentication'
              # authentication
              state.code_policy.is_authenticated = true
              state.code_policy.is_public = false
              state.code_policy.authentication_comment  += filter.name + ", "
              add_trans = true
            elsif filter.sf_type == 'except_authentication'
              # Anti
              state.code_policy.is_authenticated = false
              state.code_policy.is_public = true
              state.code_policy.authentication_comment  += filter.name + ", "
            elsif filter.sf_type == 'authorization'
              state.code_policy.is_authorized = true
              state.code_policy.authorization_comment  += filter.name + ", "
              add_trans = true
            elsif filter.sf_type == 'owner_authorization'
              state.code_policy.authorization_comment  += filter.name + ", "
            elsif filter.sf_type == 'authentication_and_authorization'
              state.code_policy.is_authenticated = true
              state.code_policy.is_public = false
              state.code_policy.is_authorized = true
              state.code_policy.authentication_comment  += filter.name + ", "
              state.code_policy.authorization_comment += filter.name + ", "
              add_trans = true
            end
            filter.abstract_filter(state)
          elsif type == 'off'
            if filter.sf_type == 'authentication'
              # authentication
              state.code_policy.is_authenticated = false
              state.code_policy.is_public = true
              state.code_policy.authentication_comment  += "except " + filter.name + ", "
            elsif filter.sf_type == 'authorization'
              state.code_policy.is_authorized = false
              state.code_policy.authorization_comment  += "except " + filter.name + ", "
            elsif filter.sf_type == 'owner_authorization'
              # state.is_authorized = false
              state.code_policy.authorization_comment  += "except " + filter.name + ", "
            elsif filter.sf_type == 'except_authentication'
              # except_authentication is off
              state.code_policy.authorization_comment  += filter.name + ", "
            else
              $log.info "complete_filter() - #{state.id} #{filter.sf_type} off"
            end
          else
            fail "FATAL"
          end
        end
      elsif filter.type == 'unknown_filter'
        $log.debug "complete_filter() - TODO: #{filter.name}  #{filter.type}"
      elsif filter.type == 'unknown_command'
        $log.debug "complete_filter() - TODO: #{filter.name}  #{filter.type}"
      else # !filter
        $log.error "complete_filter() - TODO: name='#{filter.name}'  type='#{filter.type}'"
      end

      # TODO: Transition?
      if add_trans
        # For static security check (SC), this trans does not required.
        # Auth fail -> path
        # Guard
        if $generate_all_trans
          # TODO: add trans for TC gen,
          guard = ""  # get guard from filter.guard
          path  = ""  # get path from filter.path
          $log.info "complete_filter_set_flags() TODO: TRANS  #{state.id} --#{filter.name}-#{guard}--> #{path}"
        else
          # Just count
          $log.debug "complete_filter_set_flags() TODO: TRANS  #{state.id} --#{filter.name}-#{guard}--> #{path}"
        end
        $filter_added_trans_count += 1
      end
    end

    # Abstruct before filters
    def complete_filter
      $filter_added_trans_count = 0
      # All State/Methods
      $abst_states.each do |n, state|
        # TODO: where is the best place?
        state.set_url
        # Check Global filter for Class
        if $list_global_filter.size > 0 && state.type == 'controller' && state.is_protected == false && state.is_private == false
          $log.debug "complete_filter() $list_global_filter exist"

          $list_global_filter.each do |name, v|
            # V = [all|except, class_name]
            # check range
            if v[0] == 'all'
              # for ALL states => add filter
              if $abst_commands[name].nil?
                $log.error "TODO: missing cmd, #{name}"
                # TODO: add
                c = Abstraction::Command.new
                c.name  = name
                c.type  = 'unknown_filter'
                c.count = 1  # include this
                c.filenames << $filename
                c.status = 'unknown'
                $abst_commands[name] = c
                $unknown_command += 1
              else
                fc = $abst_commands[name]
                complete_filter_set_flags(state, fc, 'on')
              end
            elsif v[0] == 'except' then
              # except some classes
              class_name0 = v[1]
              class_name1 = state.model + "controller"
              if class_name0 == class_name1
                # Hit => Except => skip
                $log.error "TODO: '#{class_name0}' == '#{class_name1}'  SKIP state=#{state.id},  filter=#{name}, TODO: add to explicit exception"
              else
                # Miss => add filter
                fc = $abst_commands[name]
                complete_filter_set_flags(state, fc, 'on')
              end
            else
              $log.error "TODO: #{v[0]}"
            end
          end # each
        end # global

        unless state.before_filters.nil?
          # BF exist
          $log.debug "complete_filter() FILTER - state=#{n} filter=#{state.before_filters}"
          state.before_filters.each do |f|
            name = f[0]
            type = f[1]
            fc = $abst_commands[name]
            if fc.nil?
              # unknwon filter
              add_to_unknwon_command_list(name, 'unknown_filter')
              $unknown_command += 1
              $log.error "complete_filter() - state=#{n} filter=#{name}  => TODO: list"
            else
              # known filter
              if type == 'on'
                $log.debug "complete_filter() - state=#{n} filter=#{name}  #{fc.providedby} #{fc.status} - ON"
                complete_filter_set_flags(state, fc, type)
              elsif type == 'off'
                $log.debug "complete_filter() - state=#{n} filter=#{name}  #{fc.providedby} #{fc.status} - OFF"
                complete_filter_set_flags(state, fc, type)
              else
                $log.error "Unknown #{type}"
                fail "FATAL"
              end
            end
          end
        end # filters
      end # states
    end

    # Complete Transitions
    # v020 the destination id has been tempolary assigned by AST parser
    #      here we check the id and fix if it was missing
    def complete_transition
      app_id2id_str = ''
      $abst_transitions.each do |n, trans|
        src = $abst_states[trans.src_id]
        if trans.dst_id.nil?
          dst = nil
        else
          dst = $abst_states[trans.dst_id]
          if dst.nil?
            # TODO: form_for submit has two temp trans
            error_type  = 'transition with missing destination state'
            conf        = "'#{trans.dst_id}' => { src_id: '#{trans.src_id}', dst_id: 'TODO', type: '#{trans.type}' }"
            message     = "Distination is missing for transition id=#{trans.id}, from #{trans.src_id} to #{trans.dst_id}."
            remidiation = "Fix or delete the transition. Please set $app_id2id at 'railroadmap/abstraction.rb'. e.g. #{conf}'"
            app_id2id_comment = ''
            if trans.tentative # trans generated by form_for
              message = message + " Since the tool assign tentative destination for 'submit' in 'form_for'."
              app_id2id_comment = '# form_for'
            end
            if !$app_id2id.nil? && !$app_id2id[trans.dst_id].nil? && $app_id2id[trans.dst_id][:type] ==  trans.type && $app_id2id[trans.dst_id][:src_id] == trans.src_id
              # Hit
              if $app_id2id[trans.dst_id][:dst_id].nil?
                # Delete
                trans.invalid = true
                severity = 1
                message     = "Fixed (invalid). => " + message
              else
                # Fix
                old_id = trans.dst_id
                trans.dst_id = $app_id2id[trans.dst_id][:dst_id]
                if trans.dst_id.nil?  # bad conf
                  severity = 2
                  message     = "Bad $app_id2id. " + message
                  remidiation = "Bad $app_id2id. " + remidiation
                else
                  severity = 1
                  message  = "Fixed (#{old_id} => #{trans.dst_id}). => " + message
                end
              end
            else  # no conf
              severity = 2
            end

            # add error msg
            e = {}
            e['error_type']  = error_type
            e['message']     = message
            e['remidiation'] = remidiation
            e['severity']    = severity
            $errors.add(e)

            if severity > 1
              app_id2id_str += "  #{conf}, #{app_id2id_comment}\n"
            end
          end
        end # do
      end # def

      # Console out
      if app_id2id_str != ''
        print "\e[31m"  # red
        puts "Destination is missing, please fix the transition by setting $app_id2id in railroadmap/abstraction.rb. e.g."
        puts "---"
        puts "# {BAD_DST_ID}  => { SRC_ID, DST_ID, type }"
        puts "$app_id2id = {"
        puts app_id2id_str
        puts "}"
        puts "---"
        print "\e[0m" # reset
      end
    end

    # 20131006 SM render dst
    #
    # dst code                             file(= our MVC ID)
    # dom             action
    # -------------------------------------------------------------------------------
    # apptype         form                 apptype#_form
    # devise:password devise/shared/links  devise:password#_devise/shared/links  NG
    #                 devise/shared/links  devise:shared#_links                  OK
    # -------------------------------------------------------------------------------
    def action_code2file(dom, action)
      a = action.split('/')
      if a.size == 1
        return dom + "#_" + action
      elsif a.size == 3
        return a[0] + ':' + a[1] + '#_' + a[2]
      elsif a.size == 2
        if dom == a[0].singularize
          # layout,layouts/navigation
          return dom + "#_" + a[1]
        else
          # devise,shared/links
          # $log.error "action_code2file(#{dom},#{action})"
          return "TBD"
          # return dom + "#_" + a[1]
        end
      else
        $log.error "action_code2file(#{dom},#{action})"
        return "TBD"
      end
    end

    #
    # Added security features, countermeasure
    #
    def complete_security_transitions
      # Security?
      # [Auto] Add Variables, CSRF, Devise
      $csrf.add_variable
      # Devise
      if $use_devise
        # add abstracted variables for devise authentication
        $devise = Rails::Devise.new
        $devise.add_variable
      end

      # CanCan
      p = Abstraction::Parser::AstParser.new
      $abst_states.each do |n1, s|
        # Authentication - Devise
        if s.is_protected == false && s.is_authenticated == true
          # add trans to session#new
          # TODO: add sign_in == true to others
          $abst_transitions.each do |n2, t|
            if t.src_id == s.id
              if t.guard.nil?
                t.guard = 'sign_in == true'
              else
                t.guard += ' and sign_in == true'
              end
            end
          end
          guard = 'sign_in != true'
          trans = p.add_transition('error_redirect_to', s.id, 'C_devise:session#new', nil, guard, nil)
          trans.origin = 'auto(devise)'
        end
        #
        # CanCan
        # authorize flag -> ERROR -> home
        # TODO: depends on AC code, add ver. to set the return state
        unless s.authorize.nil?
          # TODO: get ACL
          # TODO: add guard to other trans from this state
          guard = 'role == admin'
          $abst_transitions.each do |n2, t|
            if t.src_id == s.id
              t.guard     = 'role == admin'
              t.guard_add = 'role == admin'
            end
          end

          # Add ERROR transition
          guard = 'role != admin'
          dst = "C_home#index"
          trans = p.add_transition('error_redirect_to', s.id, dst, nil, guard, nil)
          trans.origin = 'auto(cancan)'
          trans.guard_add = 'role != admin'
          $log.info "Added transition error_redirect, #{s.id} -> #{dst}"
        end
      end  # DO states
    end

    # Check the navigation error
    #  1) View -> Controller path without RBAC check
    #  2) else?
    def check_security
      $abst_states.each do |n, s|
        unless s.authorize.nil?
          # TODO: CanCan
          $abst_transitions.each do |n2, t|
            # TODO: state hold the trans list
            if t.dst_id == s.id
              # inbound Hit, check the guard in the abst level
              guard = t.block.abst_condition_success unless t.block.nil?
              if guard.nil?
                $log.error "#{s.id} missing the condition check, since the dest, #{t.id} is protected"
                t.nav_error = true
              elsif guard.gsub(' ', '').index('role==admin').nil?
                $log.error "#{s.id} may use bad the condition check(#{guard}), since the dest, #{t.id} is protected"
                t.nav_error = true
              end
            end
          end
        end
      end
    end

    #
    # Added Attack
    #
    def complete_attack_transitions
      $attacks = []
      s_count  = 0
      t_count  = 0
      p = Abstraction::Parser::AstParser.new
      # Add attack state
      if $use_devise == true
        # added anon state
        domain = 'attack#anon'
        anon_state = p.add_state('view', domain, 'nul')
        anon_state.origin = 'auto(attack)'
        anon_state.subtype = 'attack'
        s_count += 1
      end

      if $use_cancan == true
        # added user state - TODO:  set for all roles?
        domain = 'attack#user'
        user_state = p.add_state('view', domain, 'nul')
        user_state.origin = 'auto(attack)'
        user_state.subtype = 'attack'
        s_count += 1
      end

      # Look up the attack surface
      $abst_states.each do |n, s|
        # Devise
        if s.is_protected == false && !s.is_authenticated.nil?
          $log.info "complete_attack_transition Devise trans = #{n}"
          guard = nil # pub
          trans = p.add_transition('attack', anon_state.id, s.id, nil, guard, nil)
          trans.origin = 'auto(attack)'
          t_count +=  1
          a = Abstraction::Attack.new
          a.type = 'unauthenticated_access'
          a.trans = trans
          $attacks << a
        end

        # CanCan
        # Auth + User => Auth + Admin res => Error
        unless s.authorize.nil?
          $log.info "complete_attack_transition CanCan trans = #{n}"
          guard = "role == user"
          trans = p.add_transition('attack', user_state.id, s.id, nil, guard, nil)
          trans.origin = 'auto(attack)'
          trans.guard_add = 'role != admin'
          t_count +=  1

          a = Abstraction::Attack.new
          a.type = 'unauthorized_access'
          # TODO: set object/subject
          a.trans = trans
          $attacks << a
        end
      end
      return t_count
    end

    ###########################################################################
    # print statistics
    # TODO: move to output/text
    def print_stat
      puts "Number of abstraction objects"
      puts "  state      : #{$abst_states.size}"
      puts "  variables  : #{$abst_variables.size}"
      puts "  trans      : #{$abst_transitions.size}"
      puts "  dataflows  : #{$abst_dataflows.size}"

      if $verbose == 1
        puts "Verbose mode #{$verbose}"
        puts "  Global Security Properties"
        puts "    protect_from_forgery  = #{$protect_from_forgery} [#{$protect_from_forgery_filename}]"
        puts "    authentication_method = #{$authentication_method}"
        puts "  States"
        $abst_states.each do |n, v|
          v.print
        end

        puts "  Variables"
        $abst_variables.each do |n, v|
          v.print
        end

        puts "  Transitions"
        $abst_transitions.each do |n, v|
          v.print
        end

        puts "  Dataflows"
        $abst_dataflows.each do |n, v|
          v.print
        end
        puts "--- done"
      end
    end

    ###########################################################################
    # Graphviz
    # TODO: move to output/graphviz
    # Error: trouble in init_rank
    #
    def graphviz(base_filename)
      $graphviz_with_rank = false
      graphviz_bsd(base_filename)
      graphviz_dfd(base_filename)
    end

    def graphviz_bsd(base_filename)
      # Behavior and State Diagram
      g = GraphViz.new("G", rankdir: 'LR')
      if $graphviz_with_rank
        c0 = g.subgraph
        c0[rank: "same"]
        c0.add_node('View')
        c1 = g.subgraph
        c1[rank: "same"]
        c1.add_node('View(form)')
        c2 = g.subgraph
        c2[rank: "same"]
        c2.add_node('controller')
        c3 = g.subgraph
        c3[rank: "same"]
        c3.add_node('controller(redirect)')
        c4 = g.subgraph
        c4[rank: "same"]
        c4.add_node('View(out)')
        g.add_edge('View', 'View(form)')
        g.add_edge('View(form)', 'controller')
        g.add_edge('controller', 'controller(redirect)')
        g.add_edge('controller(redirect)', 'View(out)')
      else
        c0 = nil
        c1 = nil
        c2 = nil
        c3 = nil
        c4 = nil
      end

      $abst_transitions.each do |n, v|
        # TODO: png -> graphviz
        v.graphviz(g, c0, c1, c2, c3, c4)
      end

      g.output(svg:  base_filename + '_bsd.svg')
      g.output(png:  base_filename + '_bsd.png')
      g.output(pdf:  base_filename + '_bsd.pdf')
    end

    # Data Flow Diagram (DFD)
    def graphviz_dfd(base_filename)
      g = GraphViz.new("G", rankdir: 'LR')
      if $graphviz_with_rank
        c0 = g.subgraph
        c0[rank: "same"]
        c0.add_node('View')
        c1 = g.subgraph
        c1[rank: "same"]
        c1.add_node('View(form)')
        c2 = g.subgraph
        c2[rank: "same"]
        c2.add_node('controller')
        c3 = g.subgraph
        c3[rank: "same"]
        c3.add_node('controller(redirect)')
        c4 = g.subgraph
        c4[rank: "same"]
        c4.add_node('View(out)')
        g.add_edge('View', 'View(form)')
        g.add_edge('View(form)', 'controller')
        g.add_edge('controller', 'controller(redirect)')
        g.add_edge('controller(redirect)', 'View(out)')
      else
        c0 = nil
        c1 = nil
        c2 = nil
        c3 = nil
        c4 = nil
      end
      $abst_dataflows.each do |n, v|
        v.graphviz(g, c0, c1, c2, c3, c4)
      end
      g.output(svg: base_filename + '_dfd.svg')
      g.output(png: base_filename + '_dfd.png')
      g.output(pdf: base_filename + '_dfd.pdf')
    end
  end  # class MVC
end
