# -*- coding: UTF-8 -*-

require 'sorcerer'

module Abstraction
  module Parser
    # Main parser <-> MVC
    class AstParser
      # Tracer.on
      # TODO: move to AstPaeser
      def initialize
        @indent = ''
        @dsl = []
        $dataflows = []
        @ssl_required = nil
        @ssl_allowed  = nil
        # ext class
        @controller_class = nil
        @base_controller_class = nil

        # TODO
        $condition_level = -1
        $conditions = [[], [], [], [], [], [], [], []]
        $submit_variables = []
      end

      # For debug AST
      def debug_ast(msg)
        puts msg if $debug == true && $verbose > 2
      end

      # raise + dump AST
      def raise_ast(level, sexp, msg)
        $debug = true
        puts '--------------- ERR'
        parse_sexp_common(level, sexp)
        puts "ERROR #{@filename}"
        fail msg
      end

      #########################################################################
      # State
      def add_state(type, domain, filename)
        fail "$abst_states is not defined" if $abst_states.nil?

        s1 = Abstraction::State.new(domain, type)
        # Check extend
        if $abst_states[s1.id].nil?
          s = s1
        else
          s2 = $abst_states[s1.id]
          if s2.controller_class == @base_controller_class
            # Override
            s = s2
          else
            # Conflict
            $log.error "add_state type=#{type} domain=#{domain} already exist. #{filename}"
            return nil
          end
        end

        s.filename    << filename  # TODO: not stacked?
        s.origin       = 'code'
        s.is_private   = $is_private
        s.is_protected = $is_protected
        s.controller_class = @controller_class
        s.base_controller_class = @base_controller_class

        dm = domain.split('#')
        if @ssl_required.class == Hash
          s.code_policy.ssl_required = true if @ssl_required[dm[1]] == true
        else
          s.code_policy.ssl_required = @ssl_required
        end

        if @ssl_allowed.class == Hash
          s.code_policy.ssl_allowed = true if @ssl_allowed[dm[1]] == true
        else
          s.code_policy.ssl_allowed = @ssl_allowed
        end

        # Devise - Class BF
        # Before filter with Authentication check => set flag at the state
        # s.is_authenticated = @is_authenticated
        if @is_authenticated.class == Hash
          # White list
          $log.debug "#{dm[1]}"
          if @is_authenticated[dm[1]] == true
            s.code_policy.is_authenticated = true
          end
        else
          # all
          s.code_policy.is_authenticated = @is_authenticated
        end
        # No auth flag
        if @is_noauthentication.class == Hash
          if @is_noauthentication[dm[1]] == true
            s.code_policy.is_authenticated = false
          end
        end

        $abst_states[s.id] = s
        $state = s  # current state
        $log.debug "add_state #{$state.id}"
        s
      end

      ################################################################################
      # Variables
      def add_variable(type, domain, vtype, filename)
        v = Abstraction::Variable.new(domain, type, vtype)
        v.filename << filename
        v.origin = 'code'
        fail "$abst_variables is not defined" if $abst_variables.nil?

        # TODO: 2012/12/25 SM
        if $abst_variables[v.id].nil?
          $abst_variables[v.id] = v
          return v
        else
          $log.info "add_variable() type=#{type}, domain=#{domain} already exist. v.id=#{v.id}"
          $abst_variables[v.id]
        end
      end

      # Transition
      # TODO
      def add_transition(type, src_id, dst_id, dst_hint, guard, filename)
        # Check
        fail "$state is not defined" if $state.nil?
        $log.debug "add_transition() #{type}, '#{src_id}'=>'#{dst_id}'" unless dst_id.nil?
        $log.debug "add_transition() #{type}, '#{src_id}'=>'#{dst_hint}'" if dst_id.nil?

        # TODO: skip pricate method => MUST be supported by library
        # TODO: should provide a hint?
        return nil if $is_protected
        return nil if $is_private

        src = $abst_states[src_id]

        if src.is_protected
          $log.debug "skip protected contoller2 #{src_id} -> #{dst_id}"
          return nil
        elsif src.type == 'model'
          $log.error "No trans from Model, #{src_id} #{filename}"
          fail "FATAL"
        else
          # add
          t = Abstraction::Transition.new(type, src_id, dst_id, dst_hint, guard)
          t.index = $abst_transitions_count
          t.filename << @filename
          t.origin = 'code'
          # TODO: remenber the block
          t.block = $block
          fail "$abst_transitions is not defined" if $abst_transitions.nil?

          t.inc unless $abst_transitions[t.id].nil?

          $abst_transitions[t.id] = t
          $has_transition = true
          $abst_transitions_count += 1
          $transition = t  # current transition
          # DEBUG
          return t
        end
      end

      # Copy transition
      # case 1
      #   command COND ? DST1 : DST2
      #   => trans DST1 with COND == true
      #      trans DST2 with COND == false  <= copy
      # Note) we cannot add trans duaring iteration of $abst_transitions
      def copy_transition(t1)
        t2 = Abstraction::Transition.new(t1.type, t1.src_id, t1.dst_id, t1.dst_hint, t1.guard)
        t2.filename = t1.filename
        t2.origin   = t1.origin
        t2.block    = t1.block
        t2
      end

      # text => variable id
      def lookup_variable(domain, name)
        dm =  domain.split('#')
        dm[0] = 'user' if dm[0] =~ /devise/

        id = 'S_' + dm[0] + '#' + name
        return id unless $abst_variables[id].nil?

        # UNKNOWN task#_form tags S_task#tags ["./sample/app/views/tasks/_form.html.erb"]
        # TODO: has_many tags, through tag_task  =>   S_task#tags type=has_many
        $log.debug "lookup_variable UNKNOWN #{domain} #{name} #{id} #{$state.filename}"
        fail "lookup_variable UNKNOWN variable: domain=#{domain}, name=#{name}" if $robust
        id = nil
      end

      # Dataflow
      # hint is text  - TODO: or AST?
      def add_dataflow(type, subtype, src_id, src_hint, dst_id, dst_hint, filename)
        # lookup the variable
        if src_id.nil? && !src_hint.nil?
          src_id = lookup_variable($state.domain, src_hint)
          src_block = 'variable'
          dst_block = $block.id
        end

        if dst_id.nil? && !dst_hint.nil?
          dst_id = lookup_variable($state.domain, dst_hint)
          src_block = $block.id
          dst_block = 'variable'
        end

        d = Abstraction::Dataflow.new(type, subtype, src_id, src_hint, dst_id, dst_hint, nil)
        d.filename << @filename
        d.origin = 'code'
        d.src_block = src_block
        d.dst_block = dst_block
        d.index = $abst_dataflows_count

        d.inc unless $abst_dataflows[d.id].nil?

        $abst_dataflows[d.id] = d
        $abst_dataflows_count += 1
        d
      end

      #########################################################################
      # AST-> Ruby formula
      def get_ruby(sexp)
        begin
          Sorcerer.source(sexp)
        rescue => e
          # TODO
          $log.error "get_ruby #{@filename}"
          p e             # with $log.error
          pp e.backtrace  # with $log.error
          'UNKNOWN'
        end
      end

      # AST -> hash
      # 2012-03-30
      # args_add_block
      # ssl_required :new, :create, :destroy, :update
      def get_hash(sexp)
        begin
          h = {}
          if sexp[0].to_s == 'args_add_block'
            a = sexp[1]
            a.each do |aa|
              if aa[0] == :symbol_literal
                n = aa[1][1][1]
                h[n] = true
              elsif aa[0] == :bare_assoc_hash
                k =  aa[1][0][1][1][1][1]
                v =  aa[1][0][2][1][1][1]
                n = k + '=>' + v
                h[n] = true
              else
                $log.error "Unknown"
                p aa # with $log.error
                fail "Unknown"
              end
            end
          end
          h
        rescue
          $log.error "get_hash  ================"
          pp sexp # with $log.error
          raise "get_hash ERROR #{@filename}"
        end
      end

      # get_assoc_hash
      # Get assoc => value
      def get_assoc_hash(assoc, sexp)
        h = {}
        if sexp[0].to_s == 'assoc_new'
          if sexp[1][1][1][1] == assoc
            # Hit
            a = sexp[2][1]
            a.each do |aa|
              n = aa[1][1][1]
              h[n] = true
            end
          end
        end
        h
      end

      #########################################################################
      # Add class, model, controller
      # level
      # sexp
      # type : model, controller
      def add_class(level, sexp, type)
        #  Simple class name   sexp[1][1][1]
        #  Hoge::Hoge
        name      = get_ruby(sexp[1])
        ruby_code = get_ruby(sexp[2])

        @class_name = name.downcase
        $class_name = @class_name

        $is_private   = false
        $is_protected = false

        if type == 'model'
          # class Category < ActiveRecord::Base
          if sexp[2].nil?
            $list_class[name] = [nil, 'model', nil, false, false]

            if $use_cancan == true && @class_name == 'ability'
              $log.debug "Model/Class for CanCan"

              parse_sexp_common(level, sexp)
              return
            else
              $log.debug "add_class() ERROR Unknwon class, #{name} - SKIP, Is this class defined and used by application?"
              pclass = nil
              # TODO: add errors
            end
          else
            begin
              if sexp[2][0].to_s == 'var_ref' && sexp[2][1][0].to_s == '@const'
                # class AuthSourceException < Exception; end
                pclass    = sexp[2][1][1]
              else
                pclass    = sexp[2][1][1][1]  # ActiveRecode::Base
              end
            rescue => e
              $log.error "add_class ERROR Unkown class, #{name}, in the model"
            end
            $list_class[name] = [pclass, 'model', ruby_code, false, false]
          end

          if pclass != 'ActiveRecord'
            $log.debug "add_class ERROR Unknwon class, #{name} < #{pclass} - SKIP"
            ruby_code = get_ruby(sexp[2])
          end
        end  # model

        # Cntroller
        if type == 'controller'
          # clear filter list -- 20130723 SM
          $list_filter  = {}
          $is_private   = false
          $is_protected = false

          n1 = get_ruby(sexp[1])
          n2 = get_ruby(sexp[2])
          if n2 == 'ActionController::Base'
            # Root
            $is_private   = true
            $is_protected = true
          elsif n2 == 'ApplicationController'
            # TODO
            # set default actions
            # TODO: look up the def in the parent class
            # TODO: h = get_action_list(classname)
            @controller_class = n2
            @base_controller_class = 'ActionController::Base'
          else
            $log.debug "add_class controller B>A>NEW"
          end
          @controller_class = n1
          @base_controller_class = n2
          $list_class[n1] = [n2, 'controller', ruby_code, false, false]
        end

        parse_sexp_common(level, sexp)
      end

      # Check existance of before filter of method 'name'
      # get filters of this method
      # Retern
      #  Hit    => Explicitly included list
      #  Except => Explicitly excluded list
      #  None   => Nil
      #
      #  2013-08-15 New type to support Explicitly Excluded Filter  <= no Req for this. since defined by code.
      #
      #  type  Hit/Miss  => new_type
      #  ================================
      #  all     Hit     => on
      #  ---------------------------------
      #  only    Hit     => on
      #  only    Miss    => off
      #  ---------------------------------
      #  except  Hit     => off
      #  except  Miss    => on
      #  ================================
      def get_filter_lists(name)
        return nil if $list_filter.nil?
        return nil if $list_filter.size == 0

        fout = []
        $list_filter.each do |n, f|
          # n = fname
          # f = [type, list]
          type = f[0]
          list = f[1]
          if type == 'all'
            fout << [n, 'on']
          elsif type ==  'only' || type ==  'only:'
            hit = false
            list.each do |name2|
              hit = true if name == name2
            end

            if hit
              fout << [n, 'on']
            else
              fout << [n, 'off']
            end

          elsif type ==  'except' || type ==  'except:'
            hit = false
            list.each do |name2|
              hit = true if name == name2
            end
            if hit
              fout << [n, 'off']
            else
              fout << [n, 'on']
            end
          else
            $log.error "get_filters() TODO: be robust unknown type=#{type}"
            fail "FATAL"
          end
        end # each
        return fout
      end

      # Add def  (controller)
      # 2012/06/13  Oh Devise has "def resource=(new_resource)" !!
      def add_def(level, sexp, type)
        $has_transition = false
        name = sexp[1][1]
        @def_name0 = name

        # 2012/06/13  Oh Devise has "def resource=(new_resource)" !!
        @def_name = @def_name0.gsub('=', '_eq')  # =
        @def_name = @def_name0.gsub('?', '_qu')  # ?  Question
        @def_name = @def_name0.gsub('!', '_ex')  # !  exclamation

        if sexp[2][1].class == Array
          arg = 'TBD'
        else
          arg = nil
        end

        # Clear condition
        $guard = nil
        $condition_level = -1
        # Code => Abs Obj
        # controller:action => state
        if type == 'action'
          # controller state and def
          if $is_private || $is_protected
            # def => command
            if $abst_commands[@def_name0].nil?
              # application command, not abstracted
              # $log.error "add_def() #{@def_name} => UNKNOWN command #{@filename}"
              $abst_commands_local[@def_name0] = { 'filename' => @filename }
            else
              # abstracted
              if $abst_commands[@def_name0].status == 'unknown'
                $log.error "add_def() #{@def_name} => UNKNOWN command #{@filename}"
                $abst_commands_local[@def_name0] = { 'filename' => @filename }
              else
                $log.debug "add_def() #{@def_name} => KNOWN command"
              end
            end
          else
            # def => state
            # TODO: ?
            domain = @modelname + '#' + @def_name
            s = add_state('controller', domain, @filename)
            unless s.nil?
              s.start_linenum = sexp[1][2][0]
              # lookup before_filters for this states
              fs =  get_filter_lists(name)
              unless fs.nil?
                $log.debug "add_def() -  def #{name} - filter exist #{fs}"
                s.before_filters = fs
              end
            end
          end
        end # action

        parse_sexp_common(level, sexp)
        # TODO: check expricit render
        # Add default render
        # Controller
        if  type == 'action'
          dst_id = 'V_' + $state.domain
          if $abst_states[dst_id].nil?
            $log.debug "missing dst_id #{dst_id}, from #{$state.id}"
            # 2012/06/13 SKIP
            # raise "missing dst_id #{dst_id}, from #{$state.id}" if $robust
          else
            $transition = add_transition('render_def1', $state.id, dst_id, nil, $guard, @filename)
          end
        end
        # controller
        if $has_transition == false && type == 'action'
          $log.debug "ast add_def - #{domain} $has_transition == false => add_transition"
          dst_id = 'V_' + $state.domain
          $transition = add_transition('render_def2', $state.id, dst_id, nil, nil, @filename)
        end
      end

      # Add Block
      def add_block(level, sexp, type)
        # TODO
        #   if can? :delete_archived, Specification
        if type == 'if'
          pblock = $block  # push current block
          $block = $block.add_child('if', sexp[1], nil) # add child block to current block
          $guard = get_ruby(sexp[1])
          $guard_sexp = sexp[1]
          parse_sexp_common(level, sexp)
          $block = pblock
        elsif type == 'if_mod'
          pblock = $block
          $block = $block.add_child('if_mod', sexp[1], nil)
          $guard = get_ruby(sexp[1])
          $guard_sexp = sexp[1]
          parse_sexp_common(level, sexp)
          $block = pblock
        elsif type == 'elsif'
          $block = $block.add('elsif', sexp[1], nil)
          $guard = get_ruby(sexp[1])
          $guard_sexp = sexp[1]
          parse_sexp_common(level, sexp)
        elsif type == 'else'
          $block = $block.add('else', nil, nil)
          if $guard.nil?
            $guard = 'not UNKNOWN'
            $guard_sexp = nil
          else
            $guard = 'not ' + $guard
          end
          parse_sexp_common(level, sexp)
        else
          fail "ERROR add_block UNKNOWN #{type} #{$guard}"
        end
      end

      #########################################################################
      # Add command list
      # comand hash => $abst_commands[k]
      # TODO: cleanup
      def add_command_list(command_list)
        command_list.each do |k, v|
          type       = v[:type]
          providedby = v[:providedby] || 'app'
          if $abst_commands[k].nil?
            if type == 'transition'
              c = add_trans_command_to_list(k, v[:subtype])
              c.transition_path = v[:transition_path]   # Force path
              c.providedby      = providedby
            elsif type == 'filter' then
              $log.debug "init_commands() - TODO: add app filter command #{k}"
              c = Abstraction::Command.new
              c.name       = k
              c.type       = type
              c.is_sf      = v[:is_sf]
              c.sf_type    = v[:sf_type] if c.is_sf == true
              c.providedby = providedby
              c.status     = 'beta'
              # DST
              # copy dst table => extracted by compleate_filter()
              c.dst_table = v[:dest_list] unless v[:dest_num].nil?
              $abst_commands[c.name] = c
            else
              c = Abstraction::Command.new
              c.name = k
              c.type = type
              c.providedby = providedby
              c.status = 'TODO'
              $abst_commands[c.name] = c
            end
          else
            $log.error "init_commands() - command/filter '#{k}' already exist"
            fail "DEBUG"
          end  # nil
        end  # each
      end

    def add_command_to_list(classobj)
      if $abst_commands[classobj.name].nil?
        $abst_commands[classobj.name] = classobj
      else
        # no def before
        fail "'#{classobj.name}' already exist"
      end
    end

     # redirect_to XX
    def add_trans_command_to_list(name, subtype)
      cc1 = Abstraction::Command.new
      cc1.name       = name
      cc1.type       = 'transition'
      cc1.subtype    = subtype
      cc1.has_trans  = true
      cc1.providedby = 'rails'
      cc1.status     = 'beta'
      add_command_to_list(cc1)
      return cc1
    end

    def add_dataflow_command_to_list(name, subtype, is_inbound, is_outbound)
      c = Abstraction::Command.new
      c.name         = name
      c.type         = 'dataflow'
      c.subtype      = subtype
      c.has_dataflow = true
      c.is_inbound   = is_inbound
      c.is_outbound  = is_outbound
      c.providedby   = 'rails'
      c.status       = 'beta'
      add_command_to_list(c)
      return c
    end

    def add_todo_command_to_list(name, type)
      c = Abstraction::Command.new
      c.name = name
      c.type = type
      c.providedby = 'unknown'
      c.status = 'todo'
      add_command_to_list(c)
      return c
    end

      #########################################################################
      # Add command to Model
      # Code => AST => Command => Model
      # type : model, controller, view
      def add_command(level, sexp, type)
        name = sexp[1][1]
        sarg = sexp[2]
        command(level, sexp, type, name, sarg)
        parse_sexp_common(level, sexp)
      end

      # {respond.to }
      def add_method_add_arg(level, sexp, type)
        name = sexp[1][1][1]
        sarg = sexp[2][1]
        command(level, sexp, type, name, sarg)
        parse_sexp_common(level, sexp)
      end

      # Command
      def command(level, sexp, type, name, sarg)
        tdb = false
        unknown = false
        # 2012/06/13
        # UNKNOWN command name=[:var_ref, [:@const, "Mime", [13, 14]]]
        #   respond_to *Mime::SET.map(&:to_sym) if mimes_for_respond_to.empty?
        if name.class == Array
          $log.debug "TODO: #{name} is not a command? SKIP"
          return
        end

        if name.nil?
          $log.debug "TODO: nil name, SKIP"
          return
        end

        # TODO: 2012-08-08
        if $abst_commands[name].nil?
           # Unknown command
          $log.debug "TODO: command #{name} #{@filename} <==================== command"
          $log.error "command() unknown command, '#{name}' #{@filename}"
          pp sexp # with $log.error

          # add to list
          c = Abstraction::Command.new
          c.name  = name
          c.type  = 'unknown_command'
          c.count = 1  # include this
          c.filenames << $filename
          c.status = 'unknown'
          $abst_commands[name] = c
          $unknown_command += 1
        else
          # Command HIT
          # Add trans
          if $abst_commands[name].has_trans
            add_transition_by_command(name, $state, $guard, sarg, @filename)
          end

          # Add dataflow
          if $abst_commands[name].has_dataflow
            add_dataflow_by_command($abst_commands[name], $state, $guard, sarg, @filename)
          end
          # run abstract()
          $abst_commands[name].abstract(sexp, sarg, @filename)
        end # if
      end

      # TODO: common def for :args_add_block
      # [:string_literal,
      #   [:string_content, [:@tstring_content, "Sign in", [2, 15]]]],
      def get_label(sexp)
        # TODO: INV sexp == Array
        sexp.each do |s|
          if s[0] == :string_literal && s[1][0] ==  :string_content && s[1][1][0] == :@tstring_content
            return s[1][1][1]
          end
        end
        return nil
      end

      # TODO: => Manual def
      def get_path(sexp)
        # TODO: INV sexp == Array
        path = nil
        arg  = nil # TODO: set arg?

        sexp.each do |s|
          if s[0] == :method_add_arg && s[1][0] == :fcall && s[1][1][0] == :@ident
            path =  s[1][1][1]
            return path, arg
          elsif s[0] == :string_literal && s[1][0] == :string_content && s[1][1][0] == :@tstring_content
            path =  s[1][1][1]
            return path, arg
          elsif s[0] == :var_ref && s[1][0] == :@ident
            path =  s[1][1]
            return path, arg
          elsif s[0] == :bare_assoc_hash
            # format.json { render json: @authorizationtype.errors, status: :unprocessable_entity }
            return path, arg
          elsif s[0] == :symbol_literal && s[1][0] == :symbol && s[1][1][0] == :@ident
            # render :new
            # [[:symbol_literal, [:symbol, [:@ident, "new", [28, 92]]]]]
            path = s[1][1][1]
            return path, arg
          elsif s[0] == :vcall && s[1][0] == :@ident
            # redirect_to users_path, :notice => "User updated."
            # [:vcall, [:@ident, "users_path", [17, 18]]]
            path =  s[1][1]
            return path, arg
          elsif s[0] == :binary
            # redirect_to request.referrer || root_path
            # TODO: this generate two transitions
            # at this time, we select root_path
            $log.info "TODO: A || B"
            path = s[3][1][1] if s[3][0] == :vcall && s[3][1][0] == :@ident
            return path, arg
          elsif s[0] == :call
            # link_to user.name, user
            #         ^^^^^^^^^SKIP
          elsif s[0] == :var_ref
            # render action: 'show', status: :created, location: @apptype
            # [:var_ref, [:@ivar, "@apptype", [33, 34]]]
            # SKIP
            # $log.error "get_path() TODO: #{$filename} "
            # pp s
          else
            $log.error "get_path() TODO: #{$filename} "
            pp sexp
            pp s
            fail "get_path() TODO: add rule"
          end
        end
        $log.error "get_path() TODO: #{$filename} "
        pp sexp
        return path, arg
      end

      def add_transition_by_command(name, src_state, guard, sarg, filename)
        # check
        fail "src_state is not defined" if src_state.nil?
        $log.debug "add_transition_by_command(#{name}, #{src_state.id})"

        if $abst_commands[name].transition_path.nil?
          # Lazy check
          arg = get_ruby(sarg)
          trans_type = $abst_commands[name].subtype #
          path = nil
          label = nil # TODO
          dst_id = nil

          # Robust parser
          if sarg[0][0].to_s == 'command' &&  sarg[0][1][0].to_s == '@ident'
            # EX1  redirect_to edit_admin_role_path @role
            #       => path = edit_admin_role_path
            path = sarg[0][1][1]
            dst_id = $path2id[path]
          elsif sarg[0] == :args_add_block
            # EX2  link_to "Sign in", new_session_path(resource_name)
            #       => path = edit_admin_role_path
            label = get_label(sarg[1])
            path, arg = get_path(sarg[1])
            dst_id = $path2id[path]
          else
            $log.error "TODO"
          end

          # View and render => form
          if src_state.type == 'view' && name == 'render'
            # TODO: workaround for X and X/X, X/X is handled by later
            if path.nil?
              $log.info "add_transition_by_command() path is nil"
            else
              p = path.split('/')
              dst_id = 'V_' +  src_state.model + "#_" + path if p.size == 1
              $log.debug "add_transition_by_command() View and Render #{path} #{dst_id}"
            end
          end

          # TODO: xml
          $transition = add_transition(trans_type, src_state.id, dst_id, sarg, guard, filename)
        else
          # FORTH PATH
          trans_type = $abst_commands[name].subtype
          path = $abst_commands[name].transition_path
          dst_id = $path2id[path]
          $transition = add_transition(trans_type, src_state.id, dst_id, nil, guard, filename)
          $log.debug "command #{name} Trans force to #{$abst_commands[name].transition_path} #{dst_id}"
        end
      end

      # var
      def get_args_add_block(sexp)
        # pp sexp
        return sexp[1] if sexp[0] == :args_add_block
        sexp.each do |s|
          return s[1] if s[0] == :args_add_block
        end
        return nil
      end

      def get_var(sexp)
        sexp.each do |s|
          # [:symbol_literal, [:symbol, [:@ident, "email", [3, 15]]]],
          return s[1][1][1] if s[0] == :symbol_literal && s[1][0] == :symbol && s[1][1][0] == :@ident
        end
        return nil
      end

      def add_dataflow_by_command(cmd, src_state, guard, sarg, filename)
        # check
        fail "src_state is not defined" if src_state.nil?

        if $form_target.nil?
          # no target
          if cmd.name == 'stylesheet_link_tag'
            # TODO: ?
            $log.debug "DATAFLOW SKIP $form_target=#{$form_target}"
          elsif cmd.name == 'javascript_include_tag'
            $log.debug "DATAFLOW SKIP $form_target=#{$form_target}"
          else
            $log.error "DATAFLOW #{cmd.name}  state=#{src_state.id}, $form_target=#{$form_target}   #{filename}"
            fail "DEBUG"
          end
        else
          # HAML  = text_field_tag :section_name, '', class: 'input-xlarge', :placeholder => t('.new_section_placeholder')
          # HAML  = text_field_tag :rule_name,
          s1 = get_sexp(sarg, :symbol_literal)
          if s1.nil?
            $log.info "add_dataflow_by_command() - no symbol, cmd=#{cmd.name} src=#{src_state.id}"
            $log.info "SKIP"
            return
          end

          s2 = get_sexp(s1, :symbol)
          if s2.nil?
            $log.error "no symbol"
            pp s1
          end

          if s2[1][0] == :@ident
            attribute = s2[1][1]
            path = $form_target
            c_id = $path2id[path]
            c_state = $abst_states[c_id]
            if c_state.nil?
              # $form_target is model?
              m_id = "M_" + $form_target
              m_state = $abst_states[m_id]
              if m_state.nil?
                variable_id = nil
                variable_hint = nil
                $log.debug "add_dataflow_by_command() TODO: DATAFLOW cmd=#{cmd.name}, $form_target=#{$form_target}, c_id=#{c_id}"
              else
                $log.debug "add_dataflow_by_command() TODO: DATAFLOW cmd=#{cmd.name}, $form_target=#{$form_target}, m_id=#{m_id}"
                variable_id = "S_" + $form_target + "#" + attribute
                variable_hint = nil
              end
            else
              model = c_state.model
              variable_id = "S_" + model + "#" + attribute
              variable_hint = nil
            end

            if cmd.is_inbound
              if variable_id.nil?
                args_add_block = get_args_add_block(sarg)
                var = get_var(args_add_block) unless args_add_block.nil?
                variable_id = 'S_' + src_state.model + '#' + var if !src_state.model.nil? && !var.nil?
              end

              # add inbound (V->C->M) dataflow
              $log.debug "DATAFLOW IN  #{src_state.id} -> #{variable_id} #{variable_hint}"
              df = add_dataflow('in', cmd.name, src_state.id, nil, variable_id, variable_hint, filename)  # save this to current DF list
              $dataflows << df
              # add variabl to list
              $submit_variables << attribute
            end

            if cmd.is_outbound
              # add outbound (M->V) dataflow
              $log.debug "DATAFLOW OUT #{variable_id} -> #{src_state.id}"
              df = add_dataflow('out', cmd.name, variable_id, variable_hint, src_state.id, nil, filename)  # save this to current DF list
              $dataflows << df
            end
            return
          end

          $log.error "DATAFLOW #{src_state.id} -> #{cmd.name}  $form_target=#{$form_target}   #{filename}"
          fail "DEBUG"
        end
      end

      # Add command_call
      # type : view
      # ERB example
      #   <%= f.text_field :title %>   <<<
      #   <%= f.submit 'Switch Now' %>
      #   => submit
      def add_command_call(level, sexp, type)
        var_ref = sexp[1][1][1]
        type = sexp[3][1]
        var = sexp[4][1][0][1][1][1]
        sarg = sexp[4]

        command_call(level, sexp, var_ref, type, var, sarg)
        parse_sexp_common(level, sexp)
      end

      # get variable
      # var_ref => S_model#att
      def get_variable(sexp)
        state = false
        id = nil
        hint = nil

        if sexp[1][1][0].to_s == '@ivar'   # is this Model?
          hint = Sorcerer.source(sexp)  # TODO: AST-> Ruby
          model = sexp[1][1][1]
          attribute = sexp[3][1]
          if  attribute == 'each'
            # TODO: this is do_block
            $log.debug "TODO: this is do_block"  # TODO: this happen
          else
            # SRC _ID
            state = true
            id = "S_" + model.gsub('@', '') + "#" + attribute
          end
        elsif sexp[1][1][0].to_s == '@ident'   # is this variable of View erb?
          hint = Sorcerer.source(sexp)
          model = sexp[1][1][1]
          attribute = sexp[3][1]
          if  attribute == 'each'
            # TODO: this is do_block
            $log.debug "TODO: this is do_block"
          else
            # SRC _ID
            state = true
            id = "S_" + model.gsub('@', '') + "#" + attribute
          end
        elsif sexp[0].to_s == 'call' && sexp[1][0].to_s == 'var_ref' && sexp[3][0].to_s == '@ident'
          # ruby code: User.current => s_user#current ?
          hint  = Sorcerer.source(sexp)
          model = sexp[1][1][1]
          attribute = sexp[3][1]
          # TODO: is this variable state?
          state = true
          id = "S_" + model.gsub('@', '') + "#" + attribute
        else
          $log.error "get_variable ERROR unknown variable"
          ruby_code = get_ruby(sexp)
          puts "  filename : #{$filename}"
          puts "  ruby code: #{ruby_code}"
          puts "  sexp     :"
          pp sexp # with $log.error
        end

        return state, id, hint
      end

      # get variable
      # var_ref => S_model#att
      def get_variable2(sexp)
        # init
        state = false   # true -> Dataflow
        id    = nil
        hint  = Sorcerer.source(sexp)
        todo  = false

        if sexp[0] == :call
          if sexp[1][0] == :var_ref
            if sexp[1][1][0] == :@ivar && sexp[3][0] == :@ident
              # @page.user
              model  = sexp[1][1][1]
              attrib = sexp[3][1]
              state = true
              id = "S_" + model.gsub('@', '') + "#" + attrib
            elsif sexp[1][1][0] == :@ident && sexp[3][0] == :@ident
              # role.description
              model  = sexp[1][1][1]
              attrib = sexp[3][1]
              state = true
              id = "S_" + model.gsub('@', '') + "#" + attrib
            else
              # Role.all
              $log.info "get_variable2() TODO"
            end
          elsif sexp[1][0] == :vcall
            if sexp[1][1][0] == :@ident && sexp[3][0] == :@ident
              # current_user.name
              model  = sexp[1][1][1]
              attrib = sexp[3][1]
              state = true
              id = "S_" + model.gsub('@', '') + "#" + attrib
            else
              $log.info "get_variable2() TODO"
              todo = true
            end
          elsif sexp[1][0] == :call
            if sexp[1][1][0] == :var_ref && sexp[1][3][0] == :@ident && sexp[3][0] == :@ident
              #  @page.user.name  = page -> user#name
              pmodel = sexp[1][1][1][1]
              model  = sexp[1][3][1]
              attrib = sexp[3][1]
              state = true
              id = "S_" + model.gsub('@', '') + "#" + attrib
            elsif sexp[1][1][0] == :vcall && sexp[1][3][0] == :@ident && sexp[3][0] == :@ident
              #  current_user.role.name  = current_user -> user#name
              pmodel = sexp[1][1][1][1]
              model  = sexp[1][3][1]
              attrib = sexp[3][1]
              state = true
              id = "S_" + model.gsub('@', '') + "#" + attrib
            else
              $log.info "get_variable2() TODO"
            end
          else
            # role.users.map(, &:name).join
            $log.info "get_variable2() TODO"
          end
        else
          $log.info "get_variable2() TODO"
          todo = true
        end

        if todo
          $log.error "get_variable2() TODO: #{$filename}"
          pp sexp
          p hint
        end

        return state, id, hint, model, attrib
      end

      # TODO: move to View?
      # Add command call
      #
      #  View
      #    model.attribule => HTML
      #
      #  form_for block
      #    form_for(@authenticationtype) do |f|
      #     f.XXXX
      #     f.submit
      def add_call(level, sexp, type)
        unknown = true

        if type == 'view'
          s = sexp
          if s.nil?
            $log.error "add_call() TODO"
          else
            state, id, hint, model, attrib = get_variable2(sexp)
            if state
              if model == 'f' && attrib == 'submit'
                dst_id = "C_#{$form_target}#create"
                guard = "action == 'new'"
                $t1 = add_transition('submit', $state.id, dst_id, nil, guard, @filename)

                dst_id = "C_#{$form_target}#update"
                guard = "action == 'edit'"
                $t2 = add_transition('submit', $state.id, dst_id, nil, guard, @filename)

                # variables
                $t1.variables = $submit_variables
                $t2.variables = $submit_variables
                $submit_variables = []  # reset
              else
                if $xss_raw_region == true
                  $dataflows << add_dataflow('out', 'raw_out', id, hint, $state.id, nil, @filename)  # save this to current DF list
                  $xss_raw_region = false
                  $log.debug "add raw out dataflow id=#{id}, hint=#{hint}, filename=#{@filename}"
                else
                  $dataflows << add_dataflow('out', 'escaped_out', id, hint, $state.id, nil, @filename)  # save this to current DF list
                end
              end
            end
          end
        else
          $log.error "TODO: call not in View"
        end
        parse_sexp_common(level, sexp)
      end

      # Add command call
      #
      #  View
      #    form_for
      # sexp =
      #   :method_add_arg,
      #     :fcall
      #     :arg_paren,
      def add_fcall(level, sexp, type)
        # get command name
        name =  sexp[1][1][1] if sexp[1][1][0] == :@ident

        if name == 'form_for'
          var_ref = sexp[2][1]
          var = nil
          sarg = nil
          command_call(level, sexp, var_ref, name, var, sarg)
        else
          $log.info "AST - add_fcall type=#{type} name=#{name}"
          parse_sexp_common(level, sexp)
        end
      end

      # command_call parser for View(ERB)
      #   => dataflow
      def command_call(level, sexp, var_ref, type, var, sarg)
        # DIR
        # -----------------------------------
        # Output (M->V)       - label,
        # Input  (   V->C->M) - text_area text_field
        # Submit (   V->C->M) - submit
        unknown = false

        # 20130702 move to $abst_commands
        name = type
        if $abst_commands[name].nil?
          # Unknown command?
          # TODO: Call in View  eg. user.email
          # Skip for now
          if sexp[0].to_s == 'call'
            call = sexp
          else
            c = Abstraction::Command.new
            c.name  = name
            c.type  = 'unknown_command2'
            c.count = 1  # include this
            $abst_commands[name] = c
          end
        else
          cmd = $abst_commands[name]
          # Add trans
          if cmd.has_trans
            add_transition_by_command(name, $state, $guard, sarg, @filename)
          end

          # Add dataflow
          if cmd.has_dataflow
            add_dataflow_by_command(cmd, $state, $guard, sarg, @filename)
          end

          # add vars to submit list
          if cmd.is_inbound
            rubycode = get_ruby(sexp[4])
            # fail "#{rubycode}"
            $submit_variables << rubycode
          end

          # Optional abstraction for custom commands
          $abst_commands[name].abstract(sexp, nil, @filename)
        end
      end

      #########################################################################
      # AST-> AST
      # find the event_name in AST
      # TODO: limit to 2nd array => many?
      def get_sexp(sexp, event_name)
        return nil if sexp.nil?
        sexp.each do |s1|
          if s1.class == Array
            return s1 if s1[0] ==  event_name  # 1st
            s1.each do |s2|
              if s2.class == Array
                return s2 if s2[0] ==  event_name # 2nd
                s2.each do |s3|
                  if s3 == Array
                    return s3 if s3[0] ==  event_name # 3rd
                  end
                end
              end
            end
          end
        end
        # 2nd
        # TODO: recurcive call
        nil
      end

      # go deep in the AST
      def parse_sexp_common(level, sexp)
        index = 0
        sexp.each do |s|
          if s.class == Symbol
            # SKIP
          elsif s.class == String
            # SKIP
          elsif s.class == Fixnum
            # SKIP
          elsif s.class == FalseClass
            # SKIP
          elsif s.class == NilClass
            # SKIP
          elsif s.class == Array
            parse_sexp(level + 1, s)
          else
            $log.error "TODO: else"
          end
          index += 1
        end
      end
    end
  end
end
