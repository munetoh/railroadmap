#require 'ruby_parser' 
#require 'ruby2ruby'

# https://github.com/jimweirich/sourcerer 
# gem install sorcerer
# NG - NoHandlerError - not support Array
# https://github.com/stephenprater/sorcerer
# NG - NoHandlerError - not support Array
require 'sorcerer'

module Abstraction
  module Parser    
    class AstParser
      # TODO move to AstPaeser
      def initialize
        @indent = ''
        @dsl = []
        $dataflows = []
        
        # Controller method flag
        @is_private   = false
        @is_protected = false
        @ssl_required = nil
        @ssl_allowed  = nil
        
        @is_authenticated = nil
        @is_noauthentication = nil
        
        # ext class 
        @controller_class = nil
        @base_controller_class = nil
        
        # TODO
        $condition_level = -1
        $conditions = [[],[],[],[],[],[],[],[]]
        $submit_variables = []
      end
           
      def dsl
        @dsl
      end

      def error(msg)
        #if $debug == true then
        puts "ERROR " + msg
        #end
      end      
      # For debug (file IO)
      def debug(msg)
        if $debug == true then
          puts msg
        end
      end
      # For debug AST
      def debug_ast(msg)
        if $debug == true and $verbose > 2 then
          puts msg
        end
      end      
      
      # DSL
      def dsl(msg)
        if $debug == true then
          puts 'DSL ' + msg
        end
        @dsl << msg
      end

      # raise + dump AST
      def raise_ast(level, sexp, msg)
        $debug = true
        puts '--------------- ERR'
        parse_sexp_common(level, sexp)
        puts "ERROR #{@filename}"
        raise msg
      end

      #########################################################################
      # State
      def add_state(type, domain, filename)
        raise "$abst_states is not defined" if $abst_states == nil
        
        s1 = Abstraction::State.new(domain, type) 
        # Check extend         
        if $abst_states[s1.id] != nil then
          s2 = $abst_states[s1.id]
          #puts  " Existing state #{s2.controller_class} #{s2.base_controller_class} #{s2.filename}"
          #puts  " New state      #{@controller_class} #{@base_controller_class}"
          if s2.controller_class == @base_controller_class then
            # Override
            #puts "Override"
            s = s2  
          else
            # Conflict
            raise "#{type} #{domain} already exist" 
          end
        else
          s = s1          
        end
        
        
        s.filename << filename  # TODO not stacked?
        s.is_private = @is_private
        s.is_protected = @is_protected
        
        s.controller_class = @controller_class
        s.base_controller_class = @base_controller_class
        
        dm = domain.split('#')
        #puts "SM DEBUG @ssl_required #{@ssl_required.class}"
        if @ssl_required.class == Hash then
          #puts "#{dm[1]}"
          if @ssl_required[dm[1]] == true then
            s.ssl_required = true
          end
        else
          s.ssl_required = @ssl_required
        end
        
        #puts "SM DEBUG @ssl_allowed #{@ssl_allowed.class}"
        if @ssl_allowed.class == Hash then
          #puts "#{dm[1]}"
          if @ssl_allowed[dm[1]] == true then
            s.ssl_allowed = true
          end
        else
          s.ssl_allowed = @ssl_allowed
        end
        
        # Before filter with Authentication check => set flag at the state        
        #s.is_authenticated = @is_authenticated
        debug "SM DEBUG @is_authenticated #{@is_authenticated.class}"
        if @is_authenticated.class == Hash then
          # White list
          debug "#{dm[1]}"
          if @is_authenticated[dm[1]] == true then
            s.is_authenticated = true
          end
        else
          # all
          s.is_authenticated = @is_authenticated          
        end
        # No auth flag
        if @is_noauthentication.class == Hash then
          if @is_noauthentication[dm[1]] == true then
            s.is_authenticated = false
          end
        end        
        
      
        $abst_states[s.id] = s
        $state = s
        debug "add_state #{$state.id}"
        s
      end
      
      ###########################################################
      # Variables
      def add_variable(type, domain, vtype, filename)
        v = Abstraction::Variable.new(domain, type, vtype)
        v.filename << filename
        raise "$abst_variables is not defined" if $abst_variables == nil
        raise "#{type} #{domain} already exist" if $abst_variables[v.id] != nil
        $abst_variables[v.id] = v
        # NG debug "add_variable #{$variable}"
        v
      end
      
      # Transition
      # TODO
      def add_transition(type, src_id, dst_id, dst_hint, guard, filename)
        raise "$state is not defined" if $state == nil
        t = Abstraction::Transition.new(type, src_id, dst_id, dst_hint, guard)
        t.filename << @filename
        # TODO remenber the block
        t.block = $block
        raise "$abst_transitions is not defined" if $abst_transitions == nil
        
        if $abst_transitions[t.id] != nil then
          t.inc          
        end 
        $abst_transitions[t.id] = t
        $has_transition = true
        debug "add_transition #{src_id} -> #{dst_id}"        
        t 
      end
      
      
      # text => variable id
      def lookup_variable(domain, name)
        dm =  domain.split('#')
        #puts "SM DEBUG UNKNOWN #{domain} #{name}"
        #p dm
        
        if dm[0] =~ /devise/ then
          dm[0] = 'user'
        end
        
        id = 'S_' + dm[0] + '#' + name
        if $abst_variables[id] != nil then
          return id
        end
        
        # UNKNOWN task#_form tags S_task#tags ["./sample/app/views/tasks/_form.html.erb"]
        # TODO has_many tags, through tag_task  =>   S_task#tags type=has_many
        
        debug "lookup_variable UNKNOWN #{domain} #{name} #{id} #{$state.filename}"
        raise "lookup_variable UNKNOWN variable: domain=#{domain}, name=#{name}" if $robust
        id = nil
      end
      
      # Dataflow
      # hint is text  - TODO or AST?
      def add_dataflow(type, src_id, src_hint, dst_id, dst_hint, filename)
        # lookup the variable
        if src_id == nil and src_hint != nil then
          src_id = lookup_variable($state.domain, src_hint)
          src_block = 'variable'
          dst_block = $block.id
          debug "SM DEBUG lookup the variable #{src_hint}? at #{$state.id} => #{src_id}"            
        end
        if dst_id == nil and dst_hint != nil then
          dst_id = lookup_variable($state.domain, dst_hint)
          src_block = $block.id
          dst_block = 'variable'
          debug "SM DEBUG lookup the variable #{dst_hint}? at #{$state.id} => #{dst_id}"  
        end
        
        d = Abstraction::Dataflow.new(type, src_id, src_hint, dst_id, dst_hint, nil)
        d.filename << @filename
        d.src_block = src_block
        d.dst_block = dst_block
         
        
        if $abst_dataflows[d.id] != nil then
          d.inc          
        end 
        $abst_dataflows[d.id] = d
        debug "add_dataflow #{type} #{d.id}"
        d
      end

      #########################################################################
      # AST-> Ruby formula
      def get_ruby(sexp)
        begin
          Sorcerer.source(sexp)
        rescue => e
          # TODO
          error "get_ruby #{@filename}"
          p e
          pp e.backtrace
          'UNKNOWN'
        end
      end
      
      # AST -> hash
      # 2012-03-30
      # ssl_required :new, :create, :destroy, :update
      def get_hash(sexp)
        h = Hash.new
        if sexp[0].to_s == 'args_add_block' then
          a = sexp[1]
          a.each do |aa|
            n = aa[1][1][1]
            h[n] = true
          end
        end
        h
      end
      
      def get_assoc_hash(assoc,sexp)
        h = Hash.new
        if sexp[0].to_s == 'assoc_new' then
          debug "SM DEBUG HIT assoc_new"
          #pp sexp
          #pp sexp[1][1][1][1]
          if sexp[1][1][1][1] == assoc then
            debug "SM DEBUG HIT assoc"
            #pp sexp[2][1]
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
      def add_class(level, sexp, type)
        #  Simple class name   sexp[1][1][1]
        #  Hoge::Hoge  
        #p sexp[1]
        name = get_ruby(sexp[1])
        #p name
        #name = sexp[1][1][1]
        
        @class_name = name.downcase
        if type == 'model' then
          p    = sexp[2][1][1][1]  # ActiveRecode::Base
          if p != 'ActiveRecord' then       
            raise_ast level, sexp,  "TODO - Unknown base model #{p}"
          end
        end
        
        
        # Cntroller
        if type == 'controller' then
          #puts "SM DEBUG add_class controller"
          n1 = get_ruby(sexp[1])
          n2 = get_ruby(sexp[2])
          #pp n1
          #pp n2
          
          #p    = sexp[2][1][1][1] # ActionController::Base
          
          if n2 == 'ActionController::Base' then
            # Root 
            #puts "SM DEBUG ApplicationController"           
          elsif n2 == 'ApplicationController' then            
            # TODO
            #puts "SM DEBUG  TODO add ApplicationController def"
            # set default actions
            # TODO look up the def in the parent class
            # TODO h = get_action_list(classname) 
            @controller_class = n2
            @base_controller_class ='ActionController::Base'            
            #add_state('controller', @modelname + "#index", @filename)
            #add_state('controller', @modelname + "#new", @filename)
            #add_state('controller', @modelname + "#create", @filename)
            #add_state('controller', @modelname + "#edit", @filename)
            #add_state('controller', @modelname + "#update", @filename)
            #add_state('controller', @modelname + "#destroy", @filename)
            
          else
            debug "add_class controller B>A>NEW"
            # TODO look up the def in the parent class            
          end
          @controller_class = n1
          @base_controller_class =n2
        end

        debug_ast "#{@indent.rjust(level)} #{level} class #{name} #{p} =============="
                               
        dsl "#{@indent.rjust(level)} #{type} #{@class_name} # #{p}"
        parse_sexp_common(level, sexp)
        dsl "#{@indent.rjust(level)}end"
        dsl ''
      end
      
      # 
      # Add def  (controller)
      # 
      def add_def(level, sexp, type)
        $has_transition = false
        
        name = sexp[1][1]
        @def_name = name
        if sexp[2][1].class == Array then
          arg = 'TBD'
        else
          arg = nil
        end
        
        # Clear condition
        $guard = nil
        $condition_level = -1
                
        debug_ast "#{@indent.rjust(level)} #{level} def #{name} #{arg} #{type} =============="        
        dsl "#{@indent.rjust(level)}def #{name} #{arg}"
        
        # Code => Abs Obj
        # controller:action => state
        if type == 'action' then
          # TODO           
          domain = @modelname + '#' + @def_name
          add_state('controller', domain, @filename)
          
          #s = Abstraction::State.new(n, 'controller')
          #s.filename << @filename
          ##puts "#{$abst_states.class}"
          #raise "$abst_states is not defined" if $abst_states == nil
          #raise "controller #{n} already exist" if $abst_states[s.id] != nil
          #$abst_states[s.id] = s
          
          #puts "SM DEBUG GUARD #{$state.filename}"
          #pp $conditions

        end
        
        parse_sexp_common(level, sexp)
        
        # TODO check expricit render
        
        # Controller
        if  type == 'action' then
          #if  $transition == nil then
            dst_id = 'V_' + $state.domain
            if $abst_states[dst_id] == nil then
              debug "missing dst_id #{dst_id}, from #{$state.id}"
              raise "missing dst_id #{dst_id}, from #{$state.id}" if $robust
            else
              debug "SM DEBUG no trtans in def, set default trans C->V,  #{$state.id} -> #{dst_id}"              
              $transition = add_transition('render_def1', $state.id, dst_id, nil, $guard, @filename)
            end
          #$has_transition = true
          #$has_transition = false
          #end
          debug "SM DEBUG GUARD PRINT ALL #{$state.filename}"
          #$state.print_block
        end
        
        # controller 
        if ($has_transition == false) and (type == 'action')
          debug "ast add_def - #{domain} $has_transition == false => add_transition"
          dst_id = 'V_' + $state.domain
          $transition = add_transition('render_def2', $state.id, dst_id, nil, nil, @filename)
        end
                
        dsl "#{@indent.rjust(level)}end"
        dsl ''
      end


      
      # Add Block
      def add_block(level, sexp, type)
        
        
        #args = sexp[1]
        if type == 'if' then
          pblock = $block
          $block = $block.add_child('if', sexp[1], nil)
          
          #$condition_level += 1
          #$conditions[$condition_level] << ['if', sexp[1]]
          $guard = get_ruby(sexp[1])
          debug "SM DEBUG GUARD #{$condition_level} if #{$guard}   #{$state.filename}"
                             
          dsl "#{@indent.rjust(level)}#{type} #{$guard}"
          parse_sexp_common(level, sexp)        
          dsl "#{@indent.rjust(level)}end  # #{type}" 
          $block = pblock
        elsif type == 'if_mod' then
          pblock = $block
          $block = $block.add_child('if_mod', sexp[1], nil)
          #$condition_level += 1
          #$conditions[$condition_level] << ['if_mod', sexp[1]]
          $guard = get_ruby(sexp[1])
          
          debug "SM DEBUG GUARD #{$condition_level} if_mod #{$guard}   #{$state.filename}"
          dsl "#{@indent.rjust(level)}#{type} #{$guard}"
          parse_sexp_common(level, sexp)        
          dsl "#{@indent.rjust(level)}end  # #{type}" 
          $block = pblock
        elsif type == 'elsif' then
          $block = $block.add('elsif', sexp[1], nil)
          #$conditions[$condition_level] << ['elsif', sexp[1]]
          $guard = get_ruby(sexp[1])
          debug "SM DEBUG GUARD #{$condition_level} elsif #{$guard}   #{$state.filename}"
          dsl "#{@indent.rjust(level)}#{type} #{$guard}"
          parse_sexp_common(level, sexp)        
          dsl "#{@indent.rjust(level)}end  # #{type}" 
        elsif type == 'else' then
          $block = $block.add('else', nil, nil)
          dsl "#{@indent.rjust(level-1)}#{type}"
          #puts "SM DEBUG else #{$guard}"
          # TODO array or tree
          #$conditions[$condition_level] << 'else'
          if $guard == nil then
            $guard = 'not UNKNOWN'
          else 
            $guard = 'not ' + $guard
          end
          debug "SM DEBUG GUARD #{$condition_level} else #{$guard}   #{$state.filename}"
          parse_sexp_common(level, sexp)
        else
          #error "ERROR add_block UNKNOWN #{type} #{$guard}"
          raise "ERROR add_block UNKNOWN #{type} #{$guard}"
        end
      end

      #########################################################################
      # Add command
      # type : model, controller, view
      def add_command(level, sexp, type)
        name = sexp[1][1]
        sarg = sexp[2]
        
        command(level, sexp, type, name, sarg)
        parse_sexp_common(level, sexp)
      end
      
      # {respond.to }
      def add_method_add_arg(level, sexp, type)
        debug "SM DEBUG call method_add_arg"
        name = sexp[1][1][1]
        sarg = sexp[2][1]
        #p name
        #p sarg
        
        command(level, sexp, type, name, sarg)        
        parse_sexp_common(level, sexp)        
      end
      
      # Command
      def command(level, sexp, type, name, sarg)  
        case name
        when 'redirect_to'
          arg = get_ruby(sarg)
          debug_ast "#{@indent.rjust(level)} #{level} command #{name} #{type} REDIRECT #{sarg} =============="
          dsl "#{@indent.rjust(level)}command (redirect to #{arg})"

          # Add to the transition list
          raise "$state is not defined" if $state == nil
          $transition = add_transition('redirect_to', $state.id, nil, sarg, $guard, @filename)
        when 'render'
          # TODO ignore XML
          # e.g. format.xml  { render :xml => @tag }
          arg = get_ruby(sarg)
          
          if arg =~/:xml/ then
            # TODO RANBO!
            debug "SM DEBUG XML -> ignore"
            $xml_transition = true
          else
            debug_ast "#{@indent.rjust(level)} #{level} command #{name} #{type} RENDER #{sarg} =============="
            dsl       "#{@indent.rjust(level)}command (render to #{arg})"
            
            # Add to the transition list
            raise "$state is not defined" if $state == nil
            $transition = add_transition('render', $state.id, nil, sarg, $guard, @filename)
            #t = Abstraction::Transition.new('render', $state.id, nil, arg)
            #t.filename << @filename
            #raise "$abst_transitions is not defined" if $abst_transitions == nil
            #raise "#{type} #{domain} already exist" if $abst_variables[t.id] != nil
            #$abst_transitions[t.id] = t
          end
          
        # ActionView::Helpers::UrlHelper
        when 'link_to'
          arg = get_ruby(sarg)
          #arg3 = get_ruby(sexp)
          #puts "Link_to #{sexp} - #{arg}"
          #$debug = true
          #parse_sexp_common(level, sexp)
          #$debug = false
          #puts "<<"
          
          debug_ast "#{@indent.rjust(level)} #{level} command #{name} #{type} LINK #{sarg} =============="
          dsl "#{@indent.rjust(level)}command (link to #{arg})"

          # Add to the transition list
          raise "$state is not defined" if $state == nil
          $transition = add_transition('link_to', $state.id, nil, sarg, $guard, @filename)
        
        # Models
        when 'attr_accessible'
          # Mass injection
          # TODO list -> each variable at model.rb
          $attr_accessible = sarg
        
        # TODO 
        
        # Devise
        when 'render_with_scope'
          # Devise - render_with_scope
          arg = get_ruby(sarg)
          $transition = add_transition('render_with_scope', $state.id, nil, sarg, $guard, @filename)
          
        # ActionController::Filters::ClassMethods
        when 'before_filter'
          # Devise 
          #  before_filter :authenticate_user!
          #  before_filter :authenticate_user!, :only => [:edit, :update, :destroy]
          # TODO set trans. to the each action
          
          # TODO DEBUG
          arg = get_ruby(sexp[2])
          #h = get_hash(sarg)
          debug "ast.rb command, TODO before_filter #{arg}"
          #pp sarg
          
          # TODO
          #
          # Devise
          #   lib/devise/controllers/helpers.rb
          if arg =~ /(:authenticate_user!)/ then
            $authentication_method = 'devise'      
            if arg =~ /(only)/ then
              #debug "SM DEBUG only => "
              # TODO
              a = sarg[1][1][1][0]
              #pp a
              @is_authenticated = get_assoc_hash('only',a)
              #pp @is_authenticated
            else
              @is_authenticated = true
            end
                        
          #  add_transition('before_filter', $state.id, nil, $1, nil, @filename)
          end
        
        # ActionController::Filters::ClassMethods
        when 'prepend_before_filter'
          arg = get_ruby(sexp[2])
          debug "command prepend_before_filter #{arg} #{@filename}"
          if arg =~ /(require_no_authentication)/ then
            $authentication_method = 'devise'
            @is_authenticated = true  
            if arg =~ /(only)/ then
              #debug "SM DEBUG only => "
              # TODO
              a = sarg[1][1][1][0]
              #pp a
              @is_noauthentication = get_assoc_hash('only',a)
            end                        
          end
          if arg =~ /(authenticate_scope)/ then
            $authentication_method = 'devise'
            if arg =~ /(only)/ then
              #debug "SM DEBUG only => "
              # TODO
              a = sarg[1][1][1][0]
              #pp a
              @is_authenticated = get_assoc_hash('only',a)
            else
              @is_authenticated = true
            end
          end
          #p @is_authenticated
          #pp @is_noauthentication
        
        # ActionController::Filters::ClassMethods
        # TODO when 'skip_before_filter'

        
        # TODO sign_in
        
        when 'respond_to'
          debug "ast.rb command, respond_to"
          $respond_to = true
        
        # ActionView::Helpers::FormTagHelper
        # TODO when 'text_field_tag'
        # TODO when 'password_field_tag'
        # TODO when 'submit_tag'
        
        # ActionView::Helpers::AssetTagHelper
        # TODO when 'javascript_include_tag'
        # TODO when 'stylesheet_link_tag'

        # ActionView::Helpers::UrlHelper
        when 'button_to'
          # button_to "Checkout", new_order_path, method: => :get,
          # button_to "Empty cart", cart, method: => :delete, confirm: => "Are you sure?"
          $transition = add_transition('button_to', $state.id, nil, sarg, $guard, @filename)

        
        # SSL 
        when 'ssl_required'
          if sarg != nil then
            @ssl_required = get_hash(sarg)
          else
            @ssl_required = true
          end
          # @ssl_required = true
          # TODO hash select method
          #p @ssl_required
        when 'ssl_allowed'
          if sarg != nil then
            @ssl_allowed = get_hash(sarg)
            
          else
            @ssl_allowed = true
          end
          #@ssl_allowed = true #get_hash()
          # TODO hash
          
          #p @ssl_allowed
        
        # Devise
        when 'devise'
          flist = get_hash(sarg)
          debug "command devise #{flist} #{@filename}"
          if flist['rememberable'] then
            debug "devise rememberable => add variable, boolean user#remember_me"
            add_variable('devise', 'user#remember_me', 'boolean', @filename)
          end
          if flist['registerable'] then
            debug "devise registerable => add variable, string  user#current_password"
            add_variable('devise', 'user#current_password', 'string', @filename)
          end
        #
        # TODO unknown commands
        #
        else
          debug_ast "#{@indent.rjust(level)} #{level} command #{name} #{type} =============="
          dsl "#{@indent.rjust(level)}command #{name}"
          arg = get_ruby(sarg)
          
          #puts "TODO command #{name} #{arg} #{@filename}"
          raise "UNKNOWN command #{sexp}" if $robust
        end        
        #parse_sexp_common(level, sexp)
        # "#{@indent.rjust(level)}end"
      end
      
      
      # Add command_call
      # type : view
      # ERB example
      #   <%= f.text_field :title %>
      #   <%= f.submit 'Switch Now' %>
      #   => submit 
      def add_command_call(level, sexp, type)
        
        # TODO 
        var_ref = sexp[1][1][1]
        type = sexp[3][1]
        var = sexp[4][1][0][1][1][1]
        debug "SM DEBUG add_command_call  $block_var=#{$block_var} #{var_ref}.#{type}  #{var}"
        
        command_call(level, sexp, var_ref, type, var)
                
        parse_sexp_common(level, sexp)
      end
      
      # Add command call
      def add_call(level, sexp, type)
        
        # TODO 
        var_ref = sexp[1][1][1]
        
        if $block_var.index(var_ref) != nil and sexp[3][0].to_s == '@ident' then
          # e.g. block_var.submit
          type = sexp[3][1]
          command_call(level, sexp, var_ref, type, nil)
        else
          raise "UNKNOWN call #{sexp}" if $robust
          type = 'UNKNOWN'
        end
        
        debug "ast add_call  $block_var=#{$block_var} var_ref=#{var_ref} type=#{type}"     
        
        
        
        parse_sexp_common(level, sexp)    
      end
      
      #
      # command_call parser for View(ERB)
      def command_call(level, sexp, var_ref, type, var)
        # DIR
        # -----------------------------------
        # Output (M->V)    - label,
        # Input  (V->C->M) - text_area text_field
        # Submit (V->C->M) - submit
        case type
        when 'label'
          # TODO src? <- $block_ver
          dsl "#{@indent.rjust(level)}label(#{var})"
          # TODO add dataflow
          $dataflows << add_dataflow('label', nil, var, $state.id, nil, @filename)
        when 'text_field'
          dsl "#{@indent.rjust(level)}text_field(#{var})"
          # TODO add dataflow
          $dataflows << add_dataflow('text_field', $state.id, nil, nil, var, @filename)
          # TODO get ident string
          $submit_variables << sexp[4][1][0][1][1][1]
        when 'text_area'
          dsl "#{@indent.rjust(level)}text_area(#{var})"
          # TODO add dataflow
          $dataflows << add_dataflow('text_area', $state.id, nil, nil, var, @filename)
          # TODO get ident string
          $submit_variables << sexp[4][1][0][1][1][1]
        when 'password_field'
          dsl "#{@indent.rjust(level)}password_field(#{var})"
          $dataflows << add_dataflow(type, $state.id, nil, nil, var, @filename)
          # TODO get ident string
          $submit_variables << sexp[4][1][0][1][1][1]
        when 'hidden_field'
          dsl "#{@indent.rjust(level)}hidden_field(#{var})"
          $dataflows << add_dataflow(type, $state.id, nil, nil, var, @filename)
          # TODO get ident string
          $submit_variables << sexp[4][1][0][1][1][1]
        when 'check_box'
          dsl "#{@indent.rjust(level)}check_box(#{var})"
          $dataflows << add_dataflow(type, $state.id, nil, nil, var, @filename)
          # TODO get ident string
          $submit_variables << sexp[4][1][0][1][1][1]
        when 'email_field'
          dsl "#{@indent.rjust(level)}email_field(#{var})"
          $dataflows << add_dataflow(type, $state.id, nil, nil, var, @filename)
          #pp sexp
          #pp sexp[4][1]
          # TODO get ident string
          $submit_variables << sexp[4][1][0][1][1][1]
        when 'submit'
          dsl "#{@indent.rjust(level)}submit(#{var})"
          # add Transition
          t = add_transition('submit', $state.id, nil, nil, $guard, @filename)
          
          # TODO link with the dataflow
          # p $submit_variables
          t.variables = $submit_variables
          $submit_variables = []  # reset
        else
          debug "unknown command_call  #{var_ref}.#{type}  #{var}"
          raise "unknown command_call or call #{sexp}" if $robust
        end
      end
      
      
      
      # go deep in the AST
      def parse_sexp_common(level, sexp)        
        index = 0
        sexp.each do |s|
          if s.class == Symbol then
            debug_ast "#{@indent.rjust(level)} #{level}-#{index} Symbol #{s}"
          elsif s.class == String then
            debug_ast "#{@indent.rjust(level)} #{level}-#{index} String \"#{s}\""
          elsif s.class == Fixnum then
            debug_ast "#{@indent.rjust(level)} #{level}-#{index} Fixnum #{s}"
          elsif s.class == FalseClass then
            debug_ast "#{@indent.rjust(level)} #{level}-#{index} FalseClass #{s}"
          elsif s.class == NilClass then
            debug_ast "#{@indent.rjust(level)} #{level}-#{index} NilClass #{s}"
          elsif s.class == Array then
            debug_ast "#{@indent.rjust(level)} #{level}-#{index} array"
            parse_sexp(level+1, s)
          else
            debug_ast "#{@indent.rjust(level)} #{level}-#{index} ---- #{s.class}"
          end
          index += 1
        end        
      end      

    end
  end
end