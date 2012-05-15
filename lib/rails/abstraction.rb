
require 'rails/abstraction/block'
require 'rails/abstraction/state'
require 'rails/abstraction/transition'
require 'rails/abstraction/dataflow'
require 'rails/abstraction/variable'
require 'rails/abstraction/parser/ast'
require 'rails/abstraction/parser/model'
require 'rails/abstraction/parser/view'
require 'rails/abstraction/parser/controller'

require 'rails/abstraction/output/html5'
require 'rails/abstraction/output/bmethod'

require 'rails/abstraction/map'

require 'sorcerer'

#gem "ruby-graphviz"
require "graphviz"

module Abstraction

  #############################################################################
  #
  #  Routes
  #  route(URL,path)  ---> controller -----> view
  #
  class Routes
    # path -> controller
  end  

  
  #############################################################################
  # Model-View-Controller
  #
  class MVC
    #
    # Initialize MVC abstraction variables
    #
    def initialize(basedirs)
      
      if basedirs == nil then
        if $rspec_on then
          debug "Abstraction::MVC - UNIT TEST MODE"
        else
          raise "initialize fail. basedirs is nil"
        end
      else      
        @basedirs = basedirs
        
        # global and flat
        $abst_states = Hash.new
        $abst_transitions = Hash.new
        $abst_variables = Hash.new
        $abst_dataflows = Hash.new
        
        # TODO delete
        # ruby => abstaction map
        $abstmap_variable = Hash.new        # Variable id => name, type
        $abstmap_guard = Hash.new           # Ruby code   => Abstracted Guard Code
        $abstmap_guard_by_block = Hash.new  # Ruby block  => Abstracted Guard Code
        $abstmap_action = Hash.new          # Block id    => Abstracted Action Code
        
        # puts "#{$abst_states.class}"
        
        $authentication_method = nil
        $protect_from_forgery = nil
      end
      
      # Hash table to translate path to state ID
      @path2id = nil
      # Guard, Action to Abst
      @guard2abst = nil
      @action2abst = nil
            
      # TODO routes
      # TODO trans
      # TODO variables      
    end
    attr_accessor :path2id, :guard2abst, :action2abst

    # For debug MVC
    def debug(msg)
      if $debug == true then
        puts msg
      end
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
        debug "load model at : #{basedir}"
        count = 0
            
        # load db schema
        Dir.glob("#{basedir}/db/schema.rb").each{ |fn|
          debug "load model schema : #{fn}"
          
          # parse
          begin
            s = Abstraction::Parser::ModelSchema.new
            s.load(fn)
          rescue => e
            p e
            pp e.backtrace
            raise "#{fn} fail"
          end
        }

        # load app Models app/models
        dir =  basedir + "/app/models"        
        Dir.glob("#{dir}/*.rb").each{ |fn|        
          debug "load model file : #{fn}"
  
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
            raise "load #{fn} was failed"
          end
          
          count += 1
        }
        
        Dir.glob("#{dir}/*/*.rb").each{ |fn|  # TODO is this happen? 
          raise "TODO models/X/X exist :-P"
          debug "load model file : #{fn}"
          
          d2 = File.dirname(fn)
          model = File.basename(d2)
          model2 = File.basename(fn, ".rb")
          #puts "    #{model}/#{model2}"
                  
          count += 1
        }
        
        # TODO add Devise helper variables
        if $devise == true then
          add_varaible('helper',  )
        end
        
        # check
        if count == 0 then
          debug "  no model"
        else
          debug "  #{count} model files"
        end
      end
    end
    

    # Controllers
    def load_controllers
      @basedirs.each do |basedir|
        # parse models
        debug "load controller at : #{basedir}"
        count = 0
            
        # load app Models app/models
        dir =  basedir + "/app/controllers"
        
        Dir.glob("#{dir}/*.rb").each{ |fn|        
          debug "load controller file : #{fn}"
  
          # model name
          model = File.basename(fn, "_controller.rb")
          model = ActiveSupport::Inflector.singularize(model) 
          
          # parse
          begin
            c = Abstraction::Parser::Controller.new
            c.load(model, fn)
          rescue => e
            p e
            pp e.backtrace
            raise "#{fn} fail"
          end
          
          #puts "    #{model}"
          count += 1
        }
        
        Dir.glob("#{dir}/*/*.rb").each{ |fn|  # TODO is this happen? 
          debug "load controllers file : #{fn}"
          
          # model name
          d2 = File.dirname(fn)
          m1 = File.basename(d2)
          m2 = File.basename(fn, "_controller.rb")
          m3 = ActiveSupport::Inflector.singularize(m2) 
          model = m1 + ':' + m3
          
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
        }
        
        if count == 0 then
          debug "  no controller"
        else
          debug "  #{count} controller files"
        end
      end      
    end
    
 
    #
    # Views
    # ERB -> Abstraction::View
    def load_views
      @basedirs.each do |basedir|
        # parse models
        debug "load : #{basedir}"
            
        # load app Models app/models
        dir =  basedir + "/app/views"
        
        # Dir => model
        # ERB => action
        # _form => form  TODO
        
        Dir.entries(dir).map do |f|
          path = File.expand_path(f, dir)
          #puts "   model #{f}"
          
          # singularize for model
          model = ActiveSupport::Inflector.singularize(f)
          #puts "  #{f} => #{model}"
          
          if f == "." then
          elsif f == ".." then
          else        
            # Scan app/views/*/*.rb
            Dir.glob("#{path}/*.erb").each{ |fn|
              debug "load : #{fn}"

              # parse
              begin
                v = Abstraction::Parser::View.new
                v.load(model, fn)
              rescue => e
                p e
                pp e.backtrace
                raise "#{fn} fail"
              end
              
              

            }   
            Dir.glob("#{path}/*/*.erb").each{ |fn|        
              debug "load : #{fn}"
              
              if fn =~ /\/(\w+)\/(\w+)\/(\w+).(\w+).erb/ then
                #puts "#{$1} #{$2} #{$3} #{$4}"
                m1 = $1
                m2 = ActiveSupport::Inflector.singularize($2) 
                a  = $3
                t  = $4
                model =  m1 + ':' + m2
              else
                p fn
                raise "ERROR cannot se the model name"
              end
              
                        
              debug "load_views #{model} #{fn}"
              # parse
              begin
                v = Abstraction::Parser::View.new
                v.load(model, fn)
              rescue => e
                if $robust then
                  p e
                  pp e.backtrace
                  raise "#{fn} fail"
                else
                  p e
                  debug "duplicate"
                end
              end
              
            }
          end  # DIRs  
        end    
      end
    end
    
    # complete_transition T_C_task#create#1 render title=, path=
    # render            C_task#create[1]                  -> [:action => "new",             ] if (not @task.save)  ["/Users/sage/workspace/TimeFliesBy-rails3.0/app/controllers/tasks_controller.rb"]
    # [:args_add_block,
    #  [[:bare_assoc_hash,
    #    [[:assoc_new,
    #      [:symbol_literal, [:symbol, [:@ident, "action", [56, 30]]]],
    #      [:string_literal,
    #       [:string_content, [:@tstring_content, "new", [56, 41]]]]]]]],
    #  false]
    def get_assoc(sexp, symbol)
      if sexp[1][0][0].to_s == 'bare_assoc_hash' then
         #puts "bare_assoc_hash"
         h = sexp[1][0][1]
         h.each  do |a|
           if a[1][1][0].to_s == 'symbol' and  a[1][1][1][1] == 'action' then
             return a[2][1][1][1]
           end
         end
      end
      if sexp[1][0][0].to_s == 'symbol_literal' then
        return sexp[1][0][1][1][1]
      end
      if sexp[1][0][0].to_s == 'string_literal' then
        return sexp[1][0][1][1][1]
      end
      
      nil
    end
    
    #
    #
    #
    def get_assoc_hash(sexp)
      if sexp == nil
        return nil
      end
      
      hash = Hash.new
      if sexp[0].to_s == 'bare_assoc_hash' then
        a = sexp[1]
        a.each do |an|
          k = an[1][1][1][1]
          v = an[2][1][1][1]
          #puts "KV #{k} = #{v}"
          hash[k] = v
        end
      end
      return hash
    end
    
    ###########################################################################
    # Abstraction map
    # TODO  remove. just use global variables by cli
    def set_variable_abstmap(map)
      map.each do |id,a|
        $abstmap_variable[id] = a
      end
    end
    
    # Ruby => Abst
    def set_guard_abstmap(map)
      map.each do |r,a|
        $abstmap_guard[r] = a
      end
    end
    
    # Block => abst
    def set_guard_abstmap_by_block(map)
      map.each do |r,a|
        $abstmap_guard_by_block[r] = a
      end
    end
    
    # Block => abst
    def set_action_abstmap(map)
      map.each do |id,a|
        $abstmap_action[id] = a
      end
    end
    
    
    ###########################################################################
    # Complete abstractions

    #  Block/Condition
    def complete_block
      $abst_states.each do |n,s|
        state = $abst_states[n]
        debug "abstraction.complete_block  #{n}  #{state.filename}"
        s.complete_condition($abstmap_guard,$abstmap_guard_by_block) # @guard2abst)
      end
    end

    # Transitions
    
    
    # Complete
    # TODO gurad abstraction is done by state.compleate.condition => block.comp
    def complete_transition
      raise "path to id table is nil" if @path2id == nil
      
      # for each Transitions 
      $abst_transitions.each do |n,trans|
        
        src = $abst_states[trans.src_id]
        dom = src.domain.split('#')
        
        # Check fix list
        src_label = trans.src_id + '[' + trans.count.to_s + ']'
        fix = $map_fix_transitions[src_label]
        if fix != nil then
          if fix[0] then
            puts "Fix transitions #{src_label}"
            trans.dst_id = fix[1]
            # type = fix[2]
            trans.title = fix[3]
          else
            puts "Ignore transitions #{src_label}"
            trans.invalid = true
          end
        elsif trans.dst_id == nil then
          destroy = false
          sexp = trans.dst_hint
          
          # TODO use case
          if trans.type == 'link_to' or trans.type == 'button_to' then
            # [:args_add_block, 
            #  [[:string_literal, 
            #    [:string_content, 
            #     [:@tstring_content, 
            #      "new task", [185, 41]]]], 
            #   [:var_ref, 
            #    [:@ident, 
            #     "new_task_path", [185, 52]]]], false]
            title = sexp[1][0][1][1][1]
            if sexp[1][1][1][0].to_s == '@ident' then
              path = sexp[1][1][1][1]
            elsif sexp[1][1][1][0].to_s == '@ivar' then
              # link_to("Destroy", @task, :confirm => "Are you sure?", :method => :delete)
              # TODO confirm => condition,  with confirm("Are you sure?")
              #puts "SM DEBUG @ivar"
              # check assoc_hash
              hash = get_assoc_hash(sexp[1][2])
              if hash == nil
                path = sexp[1][1][1][1]
              elsif hash['method'] == 'delete'
                # should  trans to destroy
                #puts "SM DEBUG delete => "
                path = sexp[1][1][1][1]
                destroy = true
              else
                debug "complete_transition @iver unknown method?"
                #p hash
                raise "complete_transition @iver unknown method?" if $robust
              end      
            elsif sexp[1][1][1][0].to_s == 'fcall' then
              path = sexp[1][1][1][1][1]
              #puts "SM DEBUG fcall"
              #pp sexp[1][2]
              hash = get_assoc_hash(sexp[1][2])
              if hash == nil
                #path = sexp[1][1][1][1]
              elsif hash['method'] == 'delete'
                # should  trans to destroy
                #puts "SM DEBUG delete => "
                #path = sexp[1][1][1][1]
                destroy = true
              else
                debug "complete_transition, fcall unknown method?"
                #p hash
                raise "complete_transition, fcall unknown method?"  if $robust
              end
            elsif sexp[1][1][1][1][0].to_s == '@ident' then
              # <%= link_to "Back", :back %>
              path = sexp[1][1][1][1][1]
            else
              debug "complete_transition - missing path"
              #p sexp[1][1][1]     
            end
            
            # lookup
            id = @path2id[path]
            if id == nil then
              # puts "---SM DEBUG title=(#{title}) path=(#{path}) => #{id}" 
              debug "complete_transition #{trans.id} #{trans.type} title=#{title}, path=#{path} is missing"
              debug "sexp[1][1][1][0] #{sexp[1][1][1][0]}"
              if $debug then
                trans.print
                pp sexp
              end
            elsif destroy == true
              # re-map to destroy
              domain = id.split('#')
              id = domain[0] + '#destroy'
            end
            #raise "Unknown path #{path}" if id == nil
            trans.dst_id = id
            trans.title = title
          
          elsif trans.type == 'render' or trans.type == 'render_with_scope' then
            id = nil # @path2id[path]
            # TODO view
            if src.type == 'view' then
              action = get_assoc(sexp, 'action')
              if action != nil then              
                id = 'V_' + dom[0] + '#_' + action
                #puts "SM DEBUG #{id}"
              end
            end
            # TODO controller
            if src.type == 'controller' then              
              # TODO format.html { render :action => "edit" }  => V_hoge#edit
              action = get_assoc(sexp, 'action')
              if action != nil then              
                id = 'V_' + dom[0] + '#' + action
                #puts "SM DEBUG #{id}"
              end
            end
                        
            if id == nil then
              # Default
              id = 'V_' + dom[0] + '#' + dom[1]
            end
            trans.dst_id = id
          elsif trans.type == 'redirect_to' then
            id = nil
            
            # TODO stored_location_for(:user, ) || root_url, 
            # TODO   add new trans for root_url
            
            # [:args_add_block, [[:var_ref, [:@ident, "root_path", [42, 18]]]], false]
            if sexp[1][0][1][0].to_s == '@ident' then
              path = sexp[1][0][1][1]
              id = @path2id[path]
            elsif sexp[1][0][1][0].to_s == '@ivar' then
              path = sexp[1][0][1][1]
              id = @path2id[path]
            end
            
            # new_registration_path(resource_name, ), 
            if sexp[1][0][0].to_s == 'method_add_arg' then
              #puts "SM DEBUG method_add_arg"
              #p sexp[1][0][1][1][0]
              if sexp[1][0][1][1][0].to_s == '@ident' then
                
                path = sexp[1][0][1][1][1]
                id = @path2id[path]
                #puts "SM DEBUG @ident  #{path} #{id}"
              end
            end            
            
            if id == nil then
              # puts "---SM DEBUG title=(#{title}) path=(#{path}) => #{id}" 
              debug "complete_transition - id was nil, #{trans.id} #{trans.type} title=#{title}, path=#{path}"
            end
            #raise "Unknown path #{path}" if id == nil
            trans.dst_id = id
          elsif trans.type == 'submit' then
            # V_hoge#hoge -> C_hoge#create
            id = 'C_' + dom[0] + '#create'
            trans.dst_id = id
            
            # add CSRF hidden variable
            if $protect_from_forgery
              if trans.variables.size > 0 then
                trans.variables << 'csrf_token'
              else
                # TODO debug this
                $log.info "submit with no variable #{trans.id}"
              end
            end
            
          else
            raise "UNKNOWN type #{trans.type}"
          end
        end
        # check
        if trans.src_id == trans.dst_id then
          # Bad transition => invalid
          $log.info "LOOP #{trans.type} #{trans.src_id}"
          #pp trans.dst_hint
          trans.invalid = true
        end
      end  # do
    end

    ###########################################################################
    # print statistics
    # TODO move to output/text 
    def print_stat()
      puts "Number of abstraction objects"
      puts "  state      : #{$abst_states.size}"      
      puts "  variables  : #{$abst_variables.size}"
      puts "  trans      : #{$abst_transitions.size}"
      puts "  dataflows  : #{$abst_dataflows.size}"
      
      if $verbose > 0 then
        puts "Verbose mode #{$verbose}"
        puts "  Global Security Properties"
        puts "    protect_from_forgery  = #{$protect_from_forgery} [#{$protect_from_forgery_filename}]"
        puts "    authentication_method = #{$authentication_method}"
        puts "  States"
        $abst_states.each do |n,v|
          v.print
        end

        puts "  Variables"
        $abst_variables.each do |n,v|
          v.print
        end
        
        puts "  Transitions"
        $abst_transitions.each do |n,v|
          v.print
        end

        puts "  Dataflows"
        $abst_dataflows.each do |n,v|
          v.print
        end
        puts "--- done"
      end      
    end
    
    ###########################################################################
    # Graphviz
    # TODO move to output/graphviz
    # Error: trouble in init_rank
    #
    def graphviz(base_filename)
      $graphviz_with_rank = false
      graphviz_bsd(base_filename)
      graphviz_dfd(base_filename)
    end
    
    def graphviz_bsd(base_filename)
      # Behavior and State Diagram
      g = GraphViz::new( "G", :rankdir => 'LR')
      if $graphviz_with_rank then
        c0 = g.subgraph
        c0[:rank => "same"]
        c0.add_node('View')
        
        c1 = g.subgraph
        c1[:rank => "same"]
        c1.add_node('View(form)')
  
        c2 = g.subgraph
        c2[:rank => "same"]
        c2.add_node('controller')
  
        c3 = g.subgraph
        c3[:rank => "same"]
        c3.add_node('controller(redirect)')    
        
        c4 = g.subgraph
        c4[:rank => "same"]
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
      
      $abst_transitions.each do |n,v|
        # TODO png -> graphviz
        v.graphviz(g, c0, c1, c2, c3, c4)
      end
      
      
      g.output( :svg => base_filename + '_bsd.svg')
      g.output( :png => base_filename + '_bsd.png')
      
      
    end

    # Data Flow Diagram (DFD)
    def graphviz_dfd(base_filename)
      g = GraphViz::new( "G", :rankdir => 'LR')
      if $graphviz_with_rank then
        c0 = g.subgraph
        c0[:rank => "same"]
        c0.add_node('View')
        
        c1 = g.subgraph
        c1[:rank => "same"]
        c1.add_node('View(form)')
  
        c2 = g.subgraph
        c2[:rank => "same"]
        c2.add_node('controller')
  
        c3 = g.subgraph
        c3[:rank => "same"]
        c3.add_node('controller(redirect)')    
        
        c4 = g.subgraph
        c4[:rank => "same"]
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
            
      $abst_dataflows.each do |n,v|
        v.graphviz(g, c0, c1, c2, c3, c4)
      end

      g.output( :svg => base_filename + '_dfd.svg') 
      g.output( :png => base_filename + '_dfd.png')
         
      
    end
    
    # TODO
    # https://github.com/glejeune/Ruby-Graphviz/issues/10
    def png_OLD(filename)
      
      #g = GraphViz::new( "G", :ranksep => "3", :rankdir => 'LR')
      g = GraphViz::new( "G", :rankdir => 'LR')
      
      c0 = g.subgraph
      c0[:rank => "same"]
      c0.add_node('View')
      
      c1 = g.subgraph
      c1[:rank => "same"]
      c1.add_node('View(form)')

      c2 = g.subgraph
      c2[:rank => "same"]
      c2.add_node('controller')

      c3 = g.subgraph
      c3[:rank => "same"]
      c3.add_node('controller(redirect)')    
      
      c4 = g.subgraph
      c4[:rank => "same"]
      c4.add_node('View(out)')     
      
      g.add_edge('View', 'View(form)')
      g.add_edge('View(form)', 'controller')
      g.add_edge('controller', 'controller(redirect)')
      g.add_edge('controller(redirect)', 'View(out)')
      
      $abst_transitions.each do |n,v|
        v.graphviz(g, c0, c1, c2, c3, c4)
      end
      
      
      g.output( :png => filename)
    end


 
             
  end  # class MVC
end