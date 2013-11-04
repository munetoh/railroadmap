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
      load_controllers
      load_views
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
            s.load(mn, fn)
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
            s.load(mn, fn)
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

    # return symbol
    #  e.g.
    #    code render action: 'edit'
    #    get_assoc(sexp, action)  => edit
    def get_assoc(sexp, symbol_name)
      if sexp[0] == :args_add_block
        if sexp[1][0][0].to_s == 'bare_assoc_hash'
          h = sexp[1][0][1]
          h.each  do |a|
            if a[0] == :assoc_new && a[1][0] == :@label && a[1][1] == symbol_name + ':'
              # Hit symbol
              if a[2][0] == :string_literal && a[2][1][0] == :string_content && a[2][1][1][0] == :@tstring_content
                value = a[2][1][1][1]
              elsif a[2][0] == :symbol_literal && a[2][1][0] == :symbol && a[2][1][1][0] == :@ident
                value = a[2][1][1][1]
              else
                $log.error "get_assoc() - TODO: symbol='#{symbol}' #{$filename}"
                value = 'TBD'
                pp a  # with $log.error
                pp a[2][0]
                pp a[2][1][0]
                pp a[2][1][1][0]
              end
              return value
            elsif a[1][1][0] == :symbol && a[1][1][1][1] == symbol_name
              # Hit
              if a[2][1][0] == :symbol
                value = a[2][1][1][1]
              elsif a[2][1][0] == :string_content && a[2][1][1][0] == :@tstring_content
                #  render :action => "new"
                value = a[2][1][1][1]
              else
                $log.error "get_assoc() - TODO"
                pp a
                value = 'TBD'
                fail "DEBUG"
              end
              return value
            end
          end
        elsif sexp[1][0][0].to_s == 'symbol_literal'
          return sexp[1][0][1][1][1]
        elsif sexp[1][0][0].to_s == 'string_literal'
          return sexp[1][0][1][1][1]
        else
          $log.error "get_assoc() - TODO"
        end
      else
        $log.error "get_assoc() - TODO"
      end

      $log.info "get_assoc(sexp, '#{symbol_name}') MISS JSON?"
      nil
    end

    # assoc hash list => simple hash list
    # example 1
    # [:assoc_new,
    #  [:symbol_literal, [:symbol, [:@ident, "method", [5, 54]]]],
    #  [:string_literal, [:string_content, [:@tstring_content, "delete", [5, 63]]]]]
    #  => {"method"=>"delete"}
    def get_assoc_hash(sexp)
      return nil if sexp.nil?
      #  [:bare_assoc_hash,
      #   [[:assoc_new,
      #     [:@label, "method:", [17, 42]],
      #     [:symbol_literal, [:symbol, [:@ident, "delete", [17, 51]]]]],  <====
      #    [:assoc_new,
      #     [:@label, "data:", [17, 59]],
      #     [:hash,
      #      [:assoclist_from_args,
      #       [[:assoc_new,
      #         [:@label, "confirm:", [17, 67]],
      #         [:string_literal,
      #          [:string_content,
      #           [:@tstring_content, "Are you sure?", [17, 77]]]]]]]]]]]],
      hash = {}
      a = nil
      if sexp[0].to_s == 'bare_assoc_hash'
        a = sexp[1]
      elsif sexp[0].to_s == 'hash' && sexp[1].nil?
        $log.debug "get_assoc_hash ERROR unknwon syntax?"
        return hash  # nul hash
      elsif sexp[0].to_s == 'hash' && sexp[1][0].to_s == 'assoclist_from_args'
        a = sexp[1][1]
      else
        $log.error "get_assoc_hash ERROR unknwon syntax?"
        ruby_code = get_ruby(sexp)
        puts "  filename : #{@filename} OR #{$filename}"
        puts "  ruby code: #{ruby_code}"
        puts "  sexp     :"
        pp sexp # with $log.error
      end

      unless a.nil?
        a.each do |an|
          k = nil
          v = nil
          k = an[1][1][1][1] if an[1][0].to_s == 'symbol_literal'
          v = an[2][1][1][1] if an[2][0].to_s == 'string_literal'
          # ruby code: :remote => true
          v = an[2][1][1] if an[2][0].to_s == 'var_ref'
          # TODO: set ruby code for now
          v = get_ruby(an[2][1]) if an[2][0].to_s == 'method_add_arg'
          # ruby code: :columns => @report.columns
          v = get_ruby(an[2][1]) if an[2][0].to_s == 'call'
          # ruby code: :period => params[:period, ]
          v = get_ruby(an[2][1]) if an[2][0].to_s == 'aref'
          # ruby code: :set_filter => 1
          v = an[2][1] if an[2][0].to_s == '@int'
          # TODO: logic
          # ruby code: :action => (entry.is_dir? ? "show" : "changes", )
          v = get_ruby(an[2][1]) if an[2][0].to_s == 'paren'
          # ruby code: :formats => [:html, ]
          v = get_ruby(an[2][1]) if an[2][0].to_s == 'array'
          k = an[1][1] if an[1][0].to_s == '@label'
          v = an[2][1][1][1] if an[2][0].to_s == 'symbol_literal'

          v = 'TBD' if an[2][0].to_s == 'hash'

          if k.nil?
            $log.error "get_assoc_hash ERROR unknown key"
            ruby_code = get_ruby(an)
            puts "  filename : #{@filename} OR #{$filename}"
            puts "  ruby code: #{ruby_code}"
            pp an # with $log.error
          elsif v.nil?
            $log.error "get_assoc_hash ERROR unknown value"
            ruby_code = get_ruby(an)
            puts "  filename : #{@filename} OR #{$filename}"
            puts "  ruby code: #{ruby_code}"
            pp an  # with $log.error
            p an[2][0].to_s  # with $log.error
            pp an[2][1][1]  # with $log.error
          else
            hash[k] = v
          end
        end
      end
      return hash
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

    # Transitions
    # Complete
    # TODO: gurad abstraction is done by state.compleate.condition => block.comp
    def complete_transition
      fail "path to id table is nil" if @path2id.nil?
      # for new trans
      new_transitions = []
      # for each Transitions
      $abst_transitions.each do |n, trans|
        src = $abst_states[trans.src_id]
        dom = src.domain.split('#')

        # Check fix list and assign dst from sexp
        src_label = trans.src_id + '[' + trans.count.to_s + ']'
        fix = $map_fix_transitions[src_label] unless $map_fix_transitions.nil?
        if !fix.nil?
          # fix is defined by user
          if fix[0]
            puts "Fix transitions #{src_label}"
            trans.dst_id = fix[1]
            # type = fix[2]
            trans.title = fix[3]
            trans.comment = "set by $map_fix_transitions"
          else
            # no map -> igunored by user
            puts "Ignore transitions #{src_label}"
            trans.invalid = true
            trans.invalid_type =  'by $map_fix_transitions'
            trans.comment = "ignored by $map_fix_transitions"
          end
        elsif trans.dst_id.nil?
          # fix is NOT defined by user, but dest is unknown
          destroy = false
          sexp = trans.dst_hint
          ruby_code = get_ruby(sexp)

          begin
            # TODO: use case
            # View to Controller
            if trans.type == 'link_to' || trans.type == 'button_to' || trans.type == 'get'
              id = nil

              if sexp.nil?
                $log.debug "no hint"
                trans.comment += "TODO: link_to without hint (ruby code)"
              else
                # Hint => dst
                if !sexp[1].nil? && !sexp[1][1].nil? && !sexp[1][1][0].nil? && sexp[1][1][0].to_s == 'hash'
                  title = 'TBD'
                  # <%= link_to "", {:action => "remove_block", :block => block_name}, :method => 'post', :class => "close-icon" %>
                elsif !sexp[1].nil? && !sexp[1][0].nil? && !sexp[1][0][1].nil? && !sexp[1][0][1][1].nil?
                  #
                  title = sexp[1][0][1][1][1]
                elsif !sexp[1].nil?
                  ruby_code = get_ruby(sexp[1])
                  $log.error "link_to #{ruby_code}"
                  p trans.filename
                  pp sexp # with $log.error
                else
                  ruby_code = get_ruby(sexp)
                  $log.error "link_to #{ruby_code}"
                  p trans.filename
                  pp sexp  # with $log.error
                end

                if sexp[1][1].nil?
                  $log.debug "complete_transition(), unknown path"
                  path = "unknown"
                  trans.comment += "TODO: unknown link_to path CODE(#{ruby_code}"
                elsif sexp[1][1][0].to_s == 'hash'
                  # link_to label, path, option
                  #   http://railsdoc.com/references/link_to
                  #
                  # example
                  # l(:label_search, ), {:controller => "search", :action => "index", :id => @project}, :accesskey => accesskey(:search, ),
                  # <%= link_to
                  #     l(:label_search),
                  #     {:controller => 'search', :action => 'index', :id => @project},
                  #     :accesskey => accesskey(:search) %>:
                  #
                  assoc_hash = get_assoc_hash(sexp[1][1])
                  controller = nil
                  action = nil
                  path = "unknown"
                  if !assoc_hash['controller'].nil? && !assoc_hash['action'].nil?
                    controller = assoc_hash['controller']
                    action     = assoc_hash['action']
                    id = 'C_' + controller + '#_' + action
                  elsif assoc_hash['controller'].nil? && !assoc_hash['action'].nil?
                    # trans to same domain?
                    controller = dom[0]
                    action     = assoc_hash['action']
                    id = 'C_' + controller + '#_' + action
                  else
                    # see Dashboard->Navigation model->Transitions
                    $log.debug "complete_transition(), hash => unknown path,  #{trans.src_id} => ???"
                  end
                elsif sexp[1][1][1][0].to_s == '@ident'
                  path = sexp[1][1][1][1]
                  # <%= link_to 'Destroy', article, method: :delete, data: { confirm: 'Are you sure?' } %>
                  # link_to "Destroy", comment, method: => :delete, data: => {confirm: => "Are you sure?"}, )
                  if !sexp[1][2].nil? && !sexp[1][2][0].nil?
                    hash = get_assoc_hash(sexp[1][2])
                    if hash['method'] == 'delete'
                      destroy = true
                    elsif hash['method:'] == 'delete'
                      # should  trans to destroy
                      destroy = true
                    end
                  end
                elsif sexp[1][1][1][0].to_s == '@ivar'
                  # link_to("Destroy", @task, :confirm => "Are you sure?", :method => :delete)
                  # TODO: confirm => condition,  with confirm("Are you sure?")
                  # check assoc_hash
                  hash = get_assoc_hash(sexp[1][2])
                  if hash.nil?
                    path = sexp[1][1][1][1]
                  elsif hash['method'] == 'delete'
                    # should  trans to destroy
                    path = sexp[1][1][1][1]
                    destroy = true
                  else
                    $log.debug "complete_transition @iver unknown method?"
                    fail "complete_transition @iver unknown method?" if $robust
                  end
                elsif sexp[1][1][1][0].to_s == 'fcall'
                  path = sexp[1][1][1][1][1]
                  hash = get_assoc_hash(sexp[1][2])
                  if hash.nil?
                    # path = sexp[1][1][1][1]
                  elsif hash['method'] == 'delete'
                    # should  trans to destroy
                    destroy = true
                  else
                    $log.debug "complete_transition, fcall unknown method?"
                    fail "complete_transition, fcall unknown method?"  if $robust
                  end
                elsif !sexp[1][1][1][1].nil?
                  if sexp[1][1][1][1][0] == :@ident
                    # <%= link_to "Back", :back %>
                    path = sexp[1][1][1][1][1]
                  end
                else
                  $log.debug "complete_transition - missing path"
                end
              end

              if id.nil?
                # lookup, path => id
                id = @path2id[path]
                if id.nil?
                  $log.debug "complete_transition #{trans.id} #{trans.type} title=#{title}, path=#{path} is missing"
                  if $debug
                    trans.print
                    pp sexp  # debug
                  end
                elsif destroy == true
                  # re-map to destroy
                  domain = id.split('#')
                  id = domain[0] + '#destroy'
                end
              end
              # raise "Unknown path #{path}" if id == nil
              trans.dst_id = id
              trans.title = title
            elsif trans.type == 'render' || trans.type == 'render_with_scope'
              # default is
              id = nil # @path2id[path]
              # view + render (embed sub page)
              if src.type == 'view'
                if sexp[0].to_s == 'args_add_block'
                  if sexp[1][0][0].to_s == 'bare_assoc_hash'
                    hash = get_assoc_hash(sexp[1][0])
                    ruby_code = get_ruby(sexp)
                    trans.comment += "CODE(#{ruby_code})"

                    if !hash['partial'].nil?
                      # TODO
                      # <%= render :partial=>'/user_util_links' %>
                      # /user_util_links => V_#_user_util_links
                      # HAML = render partial: 'sidebar'
                      # id = 'V_' + dom[0] + '#_' + hash['partial']
                      file = hash['partial'].split('/')
                      if file.size == 2
                        id = 'V_' + file[0].singularize + '#_' + file[1]
                      else
                        id = 'V_' + dom[0] + '#_' + hash['partial']
                      end
                    elsif !hash['partial:'].nil?
                      file = hash['partial:'].split('/')
                      if file.size == 2
                        id = 'V_' + file[0] + '#_' + file[1]
                      else
                        id = 'V_' + dom[0] + '#_' + hash['partial:']
                      end
                    elsif !hash['template'].nil?
                      tmpl = hash['template'].split('/')
                      id = 'V_' + tmpl[0].singularize + '#' + tmpl[1]
                    elsif !hash['file'].nil?
                      file = hash['file'].split('/')
                      id = 'V_' + file[0].singularize + '#' + file[1]
                    else
                      # <%= solr_fname.parameterize %>"><%= render_document_show_field_label :field => solr_fname %>
                      $log.error "complete_transition()  #{trans.src_id}  ->  ruby_code #{ruby_code} UNKNOWN"
                      pp sexp
                      pp hash
                    end
                    $log.debug "complete_transition #{trans.type}, #{hash} #{ruby_code} => #{id}"
                  elsif sexp[1][0][0].to_s == 'string_literal' && sexp[1][0][1][0].to_s == 'string_content'
                    # <%= render 'constraints', :localized_params=>session[:search] %>
                    action =  sexp[1][0][1][1][1]
                    action2 = action_code2file(dom[0], action)
                    id = 'V_' + action2
                  else
                    $log.error "complete_transition() TODO"
                  end
                else
                  $log.error "complete_transition() TODO"
                  p trans.filename
                  pp sexp # with $log.error
                  fail "Unknown"
                end
              end # view

              # controller + render
              if src.type == 'controller'
                action = get_assoc(sexp, 'action')
                if action.nil?
                  # TODO: handle other cases
                  # Default C->V
                  # id = 'V_' + dom[0] + '#' + dom[1]
                  # 20130818 do not set dst_id for this
                  id = nil
                else
                  id = 'V_' + dom[0] + '#' + action
                end
              end
              trans.dst_id = id

            elsif trans.type == 'redirect_to'
              # init
              path = nil
              id   = nil
              skip = false
              if sexp.nil? || sexp == ''
                # no dst hint
                $log.debug "complete_transition() redirect_to, sexp is nil or null "
                skip = true
                trans.comment += "skip, no hint, CODE(#{ruby_code}) "
              else
                if sexp[0].to_s == 'args_add_block'
                  if sexp[1][0].to_s == 'args_add_star'
                    # redirect_to *args
                    # TODO: Not support this
                    $log.debug "complete_transition() - TODO:  not support redirect_to *arg"
                    skip = true
                    trans.comment += "skip, not supported AST CODE(#{ruby_code})"
                  elsif sexp[1][0][0].to_s == 'symbol_literal'
                    if sexp[1][0][1][0].to_s == 'symbol'
                      if sexp[1][0][1][1][0].to_s == '@ident'
                        # redirect_to :back
                        path = sexp[1][0][1][1][1]
                        id = @path2id[path]
                      else
                        $log.error "complete_transition() - TODO"
                      end
                    else
                      $log.error "complete_transition() - TODO"
                    end
                  elsif sexp[1][0][0].to_s == 'var_ref'
                    if sexp[1][0][1][0].to_s == '@ident'
                      # redirect_to feedback_complete_path
                      path = sexp[1][0][1][1]
                      id = @path2id[path]
                    elsif sexp[1][0][1][0].to_s == '@ivar'
                      # redirect_to @comment, notice: 'Comment was successfully created.'
                      # path = comment
                      path = sexp[1][0][1][1]
                      id = @path2id[path]
                    else
                      $log.error "complete_transition() - TODO:  sexp[1][0][1][0] = #{sexp[1][0][1][0]}"
                    end
                  elsif sexp[1][0][0].to_s == 'bare_assoc_hash'
                    # hash
                    $log.debug "complete_transition() - TODO:  bare_assoc_hash"
                    assoc_hash = get_assoc_hash(sexp[1][0])
                    if assoc_hash['action'].nil?
                      $log.error "complete_transition() - TODO: #{ruby_code}"
                    else
                      #  redirect_to :action => "index"
                      path = 'TBD'  # dummy
                      id = 'C_' + dom[0] + '#' + assoc_hash['action']
                    end
                  elsif sexp[1][0][0].to_s == 'method_add_arg'
                    if sexp[1][0][1][0].to_s == 'fcall'
                      if sexp[1][0][1][1][0].to_s == '@ident'
                        # redirect_to settings_path(:tab => 'notifications')
                        # TODO: check arg?
                        path = sexp[1][0][1][1][1]
                        id = @path2id[path]
                      else
                        $log.error "complete_transition() - TODO"
                      end
                    elsif sexp[1][0][1][0].to_s == 'call' then
                      # redirect_to params.update(:id => @page.title)
                      # TODO: SKIP
                      $log.debug "complete_transition() - TODO: call => skip"
                      skip = true
                      trans.comment += "skip CODE(#{ruby_code})"
                    else
                      $log.error "complete_transition() - TODO"
                    end
                  elsif sexp[1][0][0].to_s == 'ifop'
                    # TODO: dst has choice => MUST BE two transitions
                    # redirect_to(params[:continue] ? new_group_path : groups_path)
                    #   new_group_path => C_group#new
                    #   groups_path    => C_group#index
                    if sexp[1][0][1][0].to_s == 'aref'
                      # guard
                      guard_hint =  sexp[1][0][1]
                      guard_ruby = get_ruby(guard_hint)

                      # trans 1
                      if sexp[1][0][2][0].to_s == 'var_ref'
                        # trans 1 (guard == true?)
                        if sexp[1][0][2][1][0].to_s == '@ident'
                          path = sexp[1][0][2][1][1]
                          id = @path2id[path]
                          # add guard
                          if trans.guard_add.nil?
                            trans.guard_add = guard_ruby + ' == true'
                          else
                            trans.guard_add = '(' + trans.guard_add + ') and (' + guard_ruby + ' == true)'
                          end
                          $log.debug "complete_transition() - TODO: trans 1  guard is #{trans.guard_add}"
                        else
                          $log.error "complete_transition() - TODO: ifop => unknown trans 1"
                          pp sexp[1][0][2][1][0] # with $log.error
                          pp sexp[1][0][2][1][1] # with $log.error
                        end
                        # trans2
                        if sexp[1][0][3][0].to_s == 'var_ref'
                          # trans2 (guard == false)
                          if sexp[1][0][3][1][0].to_s == '@ident'
                            path2 = sexp[1][0][3][1][1]
                            id2 = @path2id[path2]
                            # add trans
                            p = Abstraction::Parser::AstParser.new
                            trans2 = p.copy_transition(trans)
                            trans2.dst_id = id2
                            # add guard
                            if trans2.guard_add.nil?
                              trans2.guard_add = guard_ruby + ' == false'
                            else
                              trans2.guard_add = '(' + trans2.guard_add + ') and (' + guard_ruby + ' == false)'
                            end
                            trans2.comment += "duplicate from #{trans.id} due to conditional path. "
                            # add
                            new_transitions << trans2
                          else
                            $log.error "complete_transition() - TODO: ifop => bad trans 2"
                          end
                        else
                          $log.error "complete_transition() - TODO: ifop => no trans 2"
                        end
                      else
                        $log.error "complete_transition() - TODO: ifop => no trans 1"
                      end
                    else
                      $log.error "complete_transition() - TODO: ifop => no guard"
                    end
                  elsif sexp[1][0][0].to_s == 'vcall'
                    if sexp[1][0][1][0].to_s == '@ident'
                      path = sexp[1][0][1][1]
                    else
                      $log.error "complete_transition() - TODO"
                    end
                  elsif sexp[1][0][0].to_s == 'string_literal'
                    if sexp[1][0][1][0].to_s == 'string_content'
                      # TODO:    sexp[1][0][1][1][0] == @tstring_content
                      # URL text?
                      url = sexp[1][0][1][1][1]
                      path = 'root' if url == "/"
                      $log.error "URL=#{url} =>  path=#{path} --- TODO"
                    else
                      $log.error "complete_transition() - TODO"
                    end
                  elsif sexp[1][0][0] == :binary
                    # redirect_to request.referrer || root_path
                    # Two path
                    # if request.referrer != nil => request.referrer
                    # else                       => root_path
                    if sexp[1][0][1][0] == :call
                      # $log.error "TODO"
                      # pp sexp[1][0][1]
                    end
                    if sexp[1][0][3][0] == :vcall && sexp[1][0][3][1][0] == :@ident
                      path = sexp[1][0][3][1][1]
                    else
                      $log.error "complete_transition() - TODO"
                    end
                  else
                    $log.error "complete_transition() - TODO"
                    pp sexp[1][0][0]
                  end    #  sexp[1][0]

                  unless sexp[1][1].nil?
                    # TODO: notice => message
                    # $log.error "complete_transition() - TODO: sexp[1][1] exist"
                    if sexp[1][1][0].to_s == 'bare_assoc_hash'
                      h = get_assoc_hash(sexp[1][1])
                      h.each do |k, v|
                        trans.add_message(k, v)
                      end
                    else
                      $log.error "complete_transition() - TODO: sexp[1][1] exist"
                      pp sexp[1][1]
                      pp sexp[1]
                      p ruby_code
                    end
                  end
                elsif sexp[0][0] == :command
                  # redirect_to edit_user_path @user
                  if sexp[0][1][0] == :@ident
                    path = sexp[0][1][1]
                  else
                    $log.error "complete_transition() TODO: command"
                  end
                else
                  $log.error "complete_transition() TODO"
                  p sexp[0]
                end
              end # if

              if skip == false && path.nil?
                # no dst path
                $log.error "complete_transition() - path is nil, #{trans.id} #{trans.type} title=#{title}"
                p trans.filename
                ruby_code = get_ruby(sexp)
                p ruby_code
                pp sexp

                fail "DEBUG missing path. check TODO: for an existance of unsupported expression."
              elsif skip == false && id.nil?
                if path == 'back'
                  # redirect_to :back
                  # TODO: Back
                  $log.debug "complete_transition() - path is back"
                  trans.comment += "TODO: skip 'back'"
                else
                  # path exist but no map to the dst id
                  # redirect_to PATH => add manual translation to the map
                  $log.debug "complete_transition() - id is nil, #{trans.id} #{trans.type} title=#{title}, path=#{path}"
                  trans.comment += "use $map_fix_transitions to set the destination manually. '#{src_label}' = [DST, TYPE, LABEL]"
                end
              end
              trans.dst_id = id
            elsif trans.type == 'submit' || trans.type == 'post'
              # V_hoge#hoge -> C_hoge#create
              id = 'C_' + dom[0] + '#create'
              trans.dst_id = id
              # add CSRF hidden variable
              if $protect_from_forgery
                if trans.variables.size > 0
                  trans.variables << 'csrf_token'
                else
                  # TODO: debug this
                  $log.info "submit with no variable #{trans.id}"
                end
              end
            else
              fail "UNKNOWN type=#{trans.type}, HALT"
            end # trans
          rescue => e
            $log.error "SEXP ERROR?"
            p e
            pp e.backtrace
            rubycode = get_ruby(sexp)
            p rubycode
            pp sexp
            raise e
          end
        else
          # fix is NOT defined by user, and dest is known
        end

        # check
        if trans.src_id == trans.dst_id
          # Bad transition => invalid
          $log.info "LOOP #{trans.type} #{trans.src_id}"
          trans.invalid = true
          trans.invalid_type =  'loop'
          # V --render-> V loop
          # something wrong
          if src.type == 'view' && trans.type == 'render'
            $log.error "View render view loop"
            pp src.id
            pp trans.filename
            pp sexp
            fail "View render view loop"
          end
        end
      end  # do

      # add new trans
      if new_transitions.length > 0
        $log.debug "complete_transition() - #{new_transitions.length} new trans exist"
        puts "    added #{new_transitions.length} transitions"
        new_transitions.each do |t2|
          t2.inc unless $abst_transitions[t2.id].nil?
          $abst_transitions[t2.id] = t2
        end
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
