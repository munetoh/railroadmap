#
# Conttroller
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
    class Controller < Abstraction::Parser::AstParser
      
      # Controller
      def parse_sexp(level, sexp) 
        
        # Class
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'class') then      
          return add_class(level, sexp, 'controller')
        end
        # Def (= Action)    
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'def') then
          return add_def(level, sexp, 'action')
        end        
        
        # TODO redirect_to
        # TODO render        
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'command') then
          return add_command(level, sexp, 'controller')
        end           

        # Block
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
        
        # method_add_block
        #  2012-03-15 copy from View
        #
        #  
        #  format.html { redirect_to(@tag, :notice => 'Tag was successfully created.') }
        #     => redirect_to tag
        #  format.html # show.html.erb
        #     => render show
        #
        if (sexp[0].class == Symbol) and (sexp[0].to_s == 'method_add_block') then
          debug "SM DEBUG method_add_block - start"
          #puts "SM DEBUG method_add_block"
          #pp sexp
          # clear possible flags
          $respond_to = false
          $has_transition = false if $has_transition != true  # TODO BAD LOGIC to avoid sub  method_add_block
          parse_sexp_common(level, sexp)
          
          if $has_transition == false and $transition == nil then
            dst_id = 'V_' + $state.domain
            debug "SM DEBUG no trtans, set default trans C->V,  #{$state.id} -> #{dst_id}"              
            $transition = add_transition('render_def3', $state.id, dst_id, nil, $guard, @filename)
            $has_transition = true
            #$has_transition = false
          end
          debug "SM DEBUG method_add_block - end"
          
          return
        end
        
        
        # do_block
        if (sexp[0].class == Symbol) and (sexp[0].to_s == 'do_block') then
          # add block_var          
          #puts "SM DEBUG do_block"
          #pp sexp
          
          # TODO
          pblock = $block
          $block = $block.add_child('do', sexp[1], nil)
          debug "SM DEBUG BLOCK DO #{pblock.id}  #{$block.id}"
          
          #  respond_to do |format|
          if sexp[1] != nil and sexp[1][0].to_s == 'block_var' and sexp[1][1][0].to_s == 'param' then
            var = sexp[1][1][1][0][1]
            $block_var << var
            debug "SM DEBUG do_block - start  $block_var = #{$block_var}"
            parse_sexp_common(level, sexp) 
            debug "SM DEBUG do_block - end    $block_var = #{$block_var}"
            # remove block_var
            $block_var.delete_if {|x| x == var}
            $block = pblock
            return
          else
            # TODO  
            # e.g. format.all do
            debug "SM DEBUG BLOCK DO do_block  - UNKNOWN"
          end
          
          
          parse_sexp_common(level, sexp) 
          $block = pblock
          return         
        end 
        if (sexp[0].class == Symbol) and (sexp[0].to_s == 'command_call') then
          debug "SM DEBUG command_call "
          #return add_command_call(level, sexp, 'controller')
        end
        
        # call
        # 
        if (sexp[0].class == Symbol) and (sexp[0].to_s == 'call') then
          
          if sexp[1] != nil and sexp[1][0].to_s == 'var_ref' and sexp[1][1][0].to_s == '@ident' then
            var_ref = sexp[1][1][1] 
            ident = sexp[3][1]
            debug "SM DEBUG call  #{var_ref} #{ident}"
            $transition = nil
            $xml_transition = nil
            parse_sexp_common(level, sexp) 
            # check default trans
            # 2012/04/26
            #   this call just contains the format.html
            #   brace_block
            #
            #
            #
            #if ident == 'html' and $transition == nil and $xml_transition == nil then
            #  puts "SM DEBUG format.html {}"
            #  pp sexp
            #  dst_id = 'V_' + $state.domain
            #  debug "SM DEBUG set default trans C->V,  #{$state.id} -> #{dst_id} if no other trans exist"         
            #  $transition = add_transition('render_def3', $state.id, dst_id, nil, $guard, @filename)
            #  $has_transition = true
            #end
            
            if ident == 'xml' then
              debug "IGNORE format.xml "
            end 
            
            return
          else
            debug "SM DEBUG call  - UNKNOWN"
          end
          #return add_call(level, sexp, 'controller')
        end

        if (sexp[0].class == Symbol) and (sexp[0].to_s == 'method_add_arg') then
          #puts "SM DEBUG call method_add_arg"
          return add_method_add_arg(level, sexp, 'controller')                    
        end        
        
        if (sexp[0].class == Symbol) and (sexp[0].to_s == 'fcall') then
          # format.html { redirect_to(@tag, :notice => 'Tag was successfully created.') }
          # format.html { redirect_to(tags_url) }
          #puts "SM DEBUG fcall "
          #return add_call(level, sexp, 'controller')
        end          
        
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'var_ref') then
          # TODO add_var_ref()
          ident = sexp[1][1]
          debug "SM DEBUG  controller var_ref ident = #{ident}"
          case ident
          when 'protected'
            @is_private   = false
            @is_protected = true            
          when 'private'
            @is_private   = true
            @is_protected = false
          when 'ssl_required'
            @ssl_required = true
          when 'protect_from_forgery'
            $protect_from_forgery = true
            $protect_from_forgery_filename = @filename
          end
        end
        
                
        # TODO variable for ERB
        # e.g. @user = current_user
        # Symbol assign
        
        
        
        parse_sexp_common(level, sexp) 
      end

      #
      # Load controller/*rb file 
      # ruby => AST => abst model
      #
      def load(modelname, filename)
        @modelname = modelname
        @filename = filename
        
        @dsl <<  "# load #{filename}"
        
        @ruby = File.read(@filename)
         
        s = Ripper::sexp(@ruby)
        
        # init
        $block_var = []
        $has_transition = false
        
        parse_sexp(0, s)
                
      end
      
      # Dump
      def print
        puts "block #{@filename}"
        $abst_states.each do |n,v|
          s = $abst_states[n]
          if s.filename[0] == @filename then 
            puts "SM DEBUG #{n}  #{s.filename}"
            v.print_block
            puts ''
          end
        end
        
      end
    end
  end
end