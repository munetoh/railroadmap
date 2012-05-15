#
# View
#

require 'rubygems'
require 'erb/stripper'

# 
require 'ripper'

# http://rubyforge.org/projects/parsetree/
#require 'ruby_parser' 
#require 'ruby2ruby'
require 'pp'

# String#pluralize  <-> String#singularize
require 'active_support/inflector'
    
#
# Abstraction of View
#
module Abstraction
  module Parser
    class View < Abstraction::Parser::AstParser
      
      
      
      # ERB Block (tree)  -- OLD
      class Block_OLD
        def initialize(parent_id, type)
          @level = 0        
          @parent = nil
          @type = type
          
          @abst_condition = nil # TODO cond for abst model
          @children = Array.new  # N
          @attribute = nil # N  list of Model/Attribute
          @contents = ''        
          # parent_id + level + type
          @id = parent_id + '_' + @type
        end
        attr_accessor :parent, :children, :contents, :type, :id
        
        
        def add_condition(cond)
          # TODO do + form_for
          if cond =~ /form_for\(([@\w]+)\)\s+\|(\w+)\|/ then
            @form_for = true
            @form_for_in = $1
            @form_for_alias = $2
            puts "form_for #{@id} #{@form_for_in} #{@form_for_alias}"
          elsif cond =~ /form_for\s+(.+)\s+\|(\w+)\|/ then
            @form_for_in = $1
            @form_for_alias = $2
            puts "form_for #{@id} #{@form_for_in} #{@form_for_alias}"
          end
          
          @condition = cond
        end
        
        
        # Transitions
        def add_submit(title, path)
          if @submit_title != nil
            puts "TODO multiple submit in this block"
            return
          end
          
          if title == nil then
            @submit_title = 'TBD'
          else
            @submit_title = title.strip
          end
          if path == nil then
            @submit_path = 'TBD'
          else
            @submit_path = path.strip
          end
          
          #puts "submit #{@submit_title} #{@submit_path}"
        end
        
        def add_linkto(title, path)
          @link_to_title = title.strip
          @link_to_path = path.strip
          #puts "link to #{@link_to_title} #{@link_to_path}"
        end
        
        # Render
        # load ?
        def add_render(form)
          #i#f form == nil then
          #  puts "TODO form is nil"
          #else
          @has_render = true
          @render = form.strip
          #puts "render #{@render}"
        end
        
        def add_contents(buf)
          # check 
          if buf =~ /link_to\s+(.+)\s*,\s*(.+)\s*;/ then
            add_linkto($1, $2)
          end
          if buf =~ /render\s+'(.+)'\s*;/ then          
            add_render($1)
          end
          if buf =~ /submit\s+(.+)\s*,\s*(.+)\s*;/ then
            add_submit($1,$2)
          elsif buf =~ /submit\s+(.+)\s*;/ then
            add_submit($1,nil)
          elsif buf =~ /submit\s*;/ then
            add_submit(nil,nil)
          end
          @contents << buf
        end
        
        #
        # create child 
        #
        def new_child(type, cond)
          #puts "new child"
          blk = Block.new(@id, type)
          blk.parent = self
          #blk.type = type
          blk.add_condition(cond)
          @children.push(blk)
          return blk
        end
        
        # TODO
        def condition2
          if @type == 'do'
            if @condition =~ /([@.\w]+).each \|(\w+)\|/ then
              @do_variable = $1
              # TODO add $2 as variable for this block, data flow? 
              # puts "#{$1} #{$2}"
              return "#{@do_variable}.size  > 0"
            end
          end
          @condition
        end
        
        # TODO
        def contents2
          @contents
        end
        
        # remove unnecessary spaces in buf      
        def strip(buf)
          if buf == nil
            return 'nil'
          end
          buf = buf.gsub(/\s+/, ' ')
          buf.strip
        end
        #
        # print details 
        #
        def print
          puts "  Block     : #{@id}"
          puts "  Type      : #{@type}"
          puts "  Condition : #{@condition}"
          puts "  Contents  : #{strip(@contents)}"
          if @link_to_title != nil then
            puts "  Link to   : #{@link_to_title} #{@link_to_path}"
          end
          if @submit_title != nil then
            puts "  Submit    : #{@submit_title} #{@submit_path}"
          end
        end
      end
  
      # http://rurema.clear-code.com/1.9.3/method/Ripper=3a=3aFilter/s/new.html
      # http://i.loveruby.net/w/RipperTutorial.TokenStreamInterface.html
      # TODO use Ripper::SexpBuilder
      class Erb2AbstView_OLD <  Ripper::Filter  # -- OLD
        
        # remove unnecessary spaces in buf      
        def strip(buf)
          if buf == nil
            return 'nil'
          end
          buf = buf.gsub(/\s+/, ' ')
          buf.strip
        end
        
        # PRE process (initialize)
        def init(id)
          blk = Block.new(id, 'root')
          #blk.type = 'root'
          @root_blk = blk
          @blk = blk
        end
      
        # POST process
        def finish
          #puts "#{@indent} BLOCK --- #{strip(@blk.contents)} ---"
          #puts "#{@indent} END"
          
          # finalize blocks        
        end
              
        # Print out block tree
        def print(level, blk)
          if level > 4
            exit
          end
          if level == 0 then
            blk = @root_blk
            puts "ERB Blocks"
            #puts "level type guard contents"
            puts "-----------------------------------"
            #puts "#{level.to_s.rjust(3)} #{blk.type.ljust(5)} - #{strip(blk.contents)}"
            blk.print
            #puts " -> #{blk.children.size} children"
            blk.children.each do |b2|
              self.print(level + 1, b2)
            end
          else
            #puts "#{level.to_s.rjust(3)} #{blk.type.ljust(5)} <#{blk.condition2}>  <#{strip(blk.contents2)}>"
            puts "-----------------------------------"
            blk.print
            #puts " -> #{blk.children.size} children"
            blk.children.each do |b2|
              self.print(level + 1, b2)
            end
          end
        end
        
        ###############################################
        # Events
        
        # default -> block contents
        def on_default(event, tok, f)
          if @cond != nil
            @cond << "#{tok}"
          else
            @cond = "#{tok}"
          end
        end
             
        # save kw (if/elsif/end)
        def on_kw(tok, f)
          @kw = tok
        end
            
        # end of the statement
        def on_semicolon(tok, f)
          if @kw == 'if'          
            #puts "IF    -- #{strip(@cond)} -- blk.type #{@blk.type}"
            # for next
            @blk = @blk.new_child('if', strip(@cond))     
          elsif @kw == 'elsif'
            # prev
            @blk = @blk.parent
            #puts "BLOCK -- #{strip(@blk.contents)} --"
            #puts "ELSIF -- #{strip(@cond)} -- blk.type #{@blk.type}"
            # for next
            @blk = @blk.new_child('elsif', strip(@cond))        
          elsif @kw == 'do'
            #puts "DO    -- #{strip(@cond)} -- blk.type #{@blk.type}"
            # for next
            @blk = @blk.new_child('do', strip(@cond))
          elsif @kw == 'end'
            #puts "BLOCK -- #{strip(@blk.contents)} --"
            @blk = @blk.parent
            #puts "#{@indent} END"     
          elsif @kw != nil
            #puts "KW[#{@kw}] -- #{strip(@cond)} -- blk.type #{@blk.type}"
            # TODO unknown kw, add to block
            @blk.add_contents "#{@cond};"
            #@blk.add_contents ";"
          else
            # not include kw => body
            #puts "BODY  blk.type #{@blk.type}"
            @blk.add_contents "#{@cond};"
            #@blk.add_contents ";"
          end
          
          @cond = nil
          @kw = nil
        end
            
        # IGNORE NL
        def on_ignored_nl(tok, f)    
        end
      end
    
    
      #
      #  parse AST
      #
      def parse_sexp(level, sexp) 
        
        # Class
        #if (sexp[0].class == Symbol) && (sexp[0].to_s == 'class') then      
        #  return add_class(level, sexp, 'controller')
        #end
        # Def (= Action)    
        #if (sexp[0].class == Symbol) && (sexp[0].to_s == 'def') then
        #  return add_def(level, sexp, 'action')
        #end        
        
        # TODO redirect_to
        # TODO render        
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'command') then
          return add_command(level, sexp, 'view')
        end           

        # Block
        # TODO add do_block 
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'if') then
          return add_block(level, sexp, 'if')
        end
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'elsif') then
          return add_block(level, sexp, 'elsif')
        end         
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'else') then
          return add_block(level, sexp, 'else')
        end
        # MOD         
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'if_mod') then
          return add_block(level, sexp, 'if_mod')
        end
        
        if (sexp[0].class == Symbol) and (sexp[0].to_s == 'do_block') then          
          # add block_var
          begin
            # <% @users.each do |user| %>
            if sexp[1] != nil then
              var = sexp[1][1][1][0][1]
              $block_var << var
              debug "parse_sexp do_block - start  $block_var = #{$block_var} #{@filename}"
              #pp sexp
              parse_sexp_common(level, sexp) 
              debug "parse_sexp do_block - end    $block_var = #{$block_var}"
              # remove block_var
              $block_var.delete_if {|x| x == var}
            else
              # without block var
              # Depot
              #  app/views/layouts/application.html.erb
              #   <%= hidden_div_if(@cart.line_items.empty?, id: 'cart') do %>
              #     <%= render @cart %>
              #  app/views/sessions/new.html.erb
              #   <%= form_tag do %>
              #    <%= text_field_tag :name, params[:name] %>
              debug "parse_sexp do_block w/o var - start #{@filename}"
              parse_sexp_common(level, sexp)
              debug "parse_sexp do_block w/o var - end"
            end
            return
          rescue => e            
            error "parse_sexp do_block - parse fail #{@filename}"
            p e
            pp sexp
            return 
          end
        end 
        
                
        # TODO SUBMIT
        if (sexp[0].class == Symbol) and (sexp[0].to_s == 'method_add_block') then
          debug "SM DEBUG method_add_block - start"
          parse_sexp_common(level, sexp)
          debug "SM DEBUG method_add_block - end"
          return
        end

        if (sexp[0].class == Symbol) and (sexp[0].to_s == 'command_call') then
          return add_command_call(level, sexp, 'view')
        end
        if (sexp[0].class == Symbol) and (sexp[0].to_s == 'call') then
          return add_call(level, sexp, 'view')
        end 
        
        parse_sexp_common(level, sexp) 
      end

      # Load view/*erb
      #  ERB -> Ruby -> AST -> abst. model
      #
      def load(modelname, filename)
        @modelname = modelname
        @filename = filename
        
        debug "load : #{modelname} #{filename}"
        
        # Model name, action
        # app/views/line_items/_line_item.text.erb
        if filename =~ /views\/(\w+)\/(\w+).(\w+).erb/ then
          @model = $1.singularize     
          @action = $2
          @format = $3
          #@id = @model + '_' + @action
        elsif filename =~ /views\/(\w+)\/(\w+)\/(\w+).(\w+).erb/ then
          @model = $1 + ':' + $2.singularize     
          @action = $3
          @format = $4
          #     
        else
          error "load,  unknown action  filename=#{filename}"
        end

        if @format != 'html' then
          @id = @model + '_' + @action + '_' + @format
          n = @modelname + "#" + @action + "#" + @format
        else
          @id = @model + '_' + @action
          n = @modelname + "#" + @action
        end 

        # new View state
        
        add_state('view', n, @filename)

        $block_var = []        
                      
        # ERB ->  Ruby
        @erb = File.read(@filename)
        @ruby = Erb::Stripper.new.to_ruby(@erb)
      
        # Ruby -> AST
        s = Ripper::sexp(@ruby)
        parse_sexp(0, s)
        
        # DEBUG
        debug "SM DEBUG GUARD #{$state.filename}"        
        pp $conditions if $debug 
        
        #@state = Abstraction::State.new(n, 'view')
        #@state.filename << @filename
        ##puts "#{$abst_states.class}"
        #raise "$abst_states is not defined" if $abst_states == nil
        #raise "model #{n} already exist" if $abst_states[@state.id] != nil
        #$abst_states[@state.id] = @state
      end
      
      
      
      # Ruby -> abstraction blocks
      def abstract_OLD      
        # puts "#{@ruby}"      
        e2a = Erb2AbstView.new(@ruby)
        e2a.init(@id)
        e2a.parse('')
        e2a.finish
        
        # TODO condition table  
        
        #puts ""
        #puts "Filename : #{@filename}"
        #puts "Model    : #{@model}"
        #puts "Action   : #{@action}"
        
        e2a.print(0, nil)   
      end
      
      
    
      #def ruby
      #  @ruby
      #end  
      #def ast
      #  @ast
      #end
    
    end
  end    
end