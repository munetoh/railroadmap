#
# Model
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
    # db/schema.rb
    class ModelSchema < Abstraction::Parser::AstParser
      
      # 
      #class Ruby2AbstModelSchema <  Ripper::Filter
      #class Ruby2AbstModelSchema <  Ripper::SexpBuilder      
      #end
      
          
      def create_table(arg)
        debug "create_table #{arg}"
        @modelname = ActiveSupport::Inflector.singularize(arg)
        
        # new Model state
        #n = 'M_' + @modelname
        @state = add_state('model', @modelname, @filename)
        #@state = Abstraction::State.new(@modelname, 'model')
        #@state.filename << @filename
        ##puts "#{$abst_states.class}"
        #raise "$abst_states is not defined" if $abst_states == nil
        #raise "model #{n} already exist" if $abst_states[@state.id] != nil
        #$abst_states[@state.id] = @state       
      end
      
      def add_attribute(type, name)
        debug " attribute #{name} #{type}"
        
        # add to Variables[]
        n = @modelname + '#' + name
        v = add_variable('model', n, type, @filename)
        # link state<->variable
        v.state = @state
        @state.add_variable v
        #s = Abstraction::Variable.new(n, 'model', type)
        #s.filename << @filename
        #s.state = @state
        ##puts "#{$abst_states.class}"
        #raise "$abst_variables is not defined" if $abst_variables == nil
        #raise "model #{n} already exist" if $abst_variables[s.id] != nil
        #$abst_variables[s.id] = s                  
      end
      
      #def debug(msg)
      #  #puts msg
      #end
      
      def parse_sexp(level, sexp)
        if sexp == nil
          return
        end
        #@indent = ''
        
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'command') then
          cmd = sexp[1][1]
          arg = sexp[2][1][0][1][1][1]
          debug "#{@indent.rjust(level)} #{level} command #{cmd} #{arg} =============="
          
          if cmd == 'create_table' then
            create_table(arg)
            @create_table_true = true
            return
          end
          @create_table_true = false
        end
  
        if (sexp[0].class == Symbol) && (sexp[0].to_s == '@ident') then
          @type = sexp[1]
          debug "#{@indent.rjust(level)} #{level} type #{@type} =============="
        end
              
        if (sexp[0].class == Symbol) && (sexp[0].to_s == '@tstring_content') && @create_table_true then
          attr = sexp[1]
          debug "#{@indent.rjust(level)} #{level} attr #{attr} =============="
          add_attribute(@type, attr)
        end
        
        parse_sexp_common(level,sexp)
      end
      
      
      # Schema(Ruby) -> AST -> Abst
      def load(filename)
        @filename = filename
        
        debug "load #{filename}"
        #raise ""
        
        @ruby = File.read(@filename)
        
        s = Ripper::sexp(@ruby)
        parse_sexp(0, s)
        
        
        # TODO devise
        #if $use_devise == true then
          #raise ""
          #add_variable('model', 'user#reset_password_token', 'TBD', 'HELPER')
          add_variable('model', 'user#password', 'TBD', 'HELPER')
          add_variable('model', 'user#password_confirmation', 'TBD', 'HELPER')
        #end
        #raise ""
      end
    end
    
    # add/models/*.rb
    class Model < Abstraction::Parser::AstParser
      
      # command
      # TODO refine arg parser  
      def add_command_OLD(level, sexp)
        cmd = sexp[1][1]
        
        arg = []
        array = sexp[2][1]
        
        index = 0  
        array.each do |a|
          # TODO make def
          if a[1][0].class == Symbol then
            if a[1][0].to_s == '@ident' then
              arg << a[1][1]
            elsif a[1][1][0].to_s == '@ident' then 
              arg << a[1][1][1]
            elsif a[1][1][0].to_s == '@tstring_content' then 
              arg << a[1][1][1]
            else
              p array
              raise "TODO unknown array #{a[1][0]} #{a[1][1][0]}"
            end
          elsif a[1][0].class == Array then
            #puts "TODO [2][1] [#{index}] [1] is NIL <==============================="
            a2 = a[1][0]
            if (a2[1][0].class == Symbol) && (a2[1][0].to_s == '@label') then              
              #  has_many :tags, through: :tag_tasks
              tmp = a2[1][1].to_s
              if (a2[2][1][1][0].class == Symbol) && (a2[2][1][1][0].to_s == '@ident') then
                arg << tmp + ' ' + a2[2][1][1][1]
              elsif (a2[2][1][1][0].class == Symbol) && (a2[2][1][1][0].to_s == '@tstring_content') then
                arg << tmp + ' ' + a2[2][1][1][1]
              elsif (a2[2][1][0].class == Symbol) && (a2[2][1][0].to_s == '@kw') then
                arg << tmp + ' ' + a2[2][1][1]
              else
                p array
                parse_sexp_common(level, a2)
                raise "TODO unknown array  #{a2}"
              end
            elsif (a2[1][0].class == Symbol) && (a2[1][0].to_s == 'symbol_literal') then
              #  has_many :tasks, :through => :tag_tasks
              if (a2[1][1][1][0].class == Symbol) && (a2[1][1][1][0].to_s == '@ident') then
                tmp = a2[1][1][1][1]
                if (a2[2][1][1][0].class == Symbol) && (a2[2][1][1][0].to_s == '@ident') then
                  arg << tmp + ' => ' + a2[2][1][1][1]
                elsif (a2[2][1][1][0].class == Symbol) && (a2[2][1][1][0].to_s == '@tstring_content') then
                  arg << tmp + ' => ' + a2[2][1][1][1]
                elsif (a2[2][1][0].class == Symbol) && (a2[2][1][0].to_s == '@kw') then
                  arg << tmp + ' => ' + a2[2][1][1]
                else
                  $debug = true
                  p array
                  parse_sexp_common(level, a2)
                  raise "TODO unknown array  #{a2}"
                end
              else
                $debug = true
                p array
                parse_sexp_common(level, a2)
                raise "TODO unknown array  #{a2}"
              end
            else
              $debug = true 
              p array
              parse_sexp_common(level, a2)
              raise "TODO unknown array  #{a2}"
            end
            
            #p a2
            #p a2[1][1]
            #p a2[][]
            
          else
            debug "TODO [2][1] [#{index}] [0] is #{a[1][1][0]} <==============================="
            p array
            debug "TODO unknown array"
          end
          # arg << a[1][1][1]            
          index += 1
        end
        # arg = sexp[2][1][0][1][1][1]
        # debug "#{@indent.rjust(level)} #{level} command #{cmd} #{arg} =============="        
        debug "#{@indent.rjust(level)}command #{cmd} #{arg}"
        parse_sexp_common(level, sexp)
      end
            
      def parse_sexp(level, sexp)
        if sexp == nil
          return
        end
        @indent = ''
        
        # class User
        # devise list of func
        # attr_accessible list -> Model
        # has_many -> link to model
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'command') then
          # puts "SM DEBUG #{sexp}"
          return add_command(level, sexp, 'model')
        end
           
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'class') then      
          return add_class(level, sexp, 'model')
        end
                
        if (sexp[0].class == Symbol) && (sexp[0].to_s == 'def') then
          return add_def(level, sexp, nil)
        end
        
        # Else
        parse_sexp_common(level, sexp)
      end
      
      # Ruby -> AST by Ripper
      def load(modelname, filename)
        @modelname = modelname
        @filename = filename
        
        # clear flags
        $attr_accessible = nil
        
        # check 
        if $abst_states[@modelname] == nil
          raise "#{modelname} is missing, check schema file"
        else
          $abst_states[@modelname].filename << @filename
        end
        
        debug "load #{filename}"
        
        @ruby = File.read(@filename)
         
        s = Ripper::sexp(@ruby)
        
        parse_sexp(0, s)
        
        # Mass injection
        # $attr_accessible
        # $attr_accessible ["email", "password", "password_confirmation", "remember_me"]
        #                    model                                         lib/
        #                             Model - Device lib - DB
        if $attr_accessible != nil then
          # look up the variable of this model
          # set flag attr_accessible = false
          list = get_ruby($attr_accessible).gsub(':','').gsub(' ','').split(',')
          #puts "SM DEBUG $attr_accessible #{list}"
          #$state.print
          vs = $state.variables 
          vs.each do |v|
            #v.print
            d = v.domain.split('#')
            v.attr_accessible = false
            
            list.each do |n|
              if n != '' then
                if n == d[1] then
                  #puts "HIT"
                  v.attr_accessible = true
                end
              end
            end
            
          end
        end
        
      end
    end
  end
end
