# -*- coding: UTF-8 -*-
# Model
#

require 'rubygems'
require 'erb/stripper' # gem install ripper2ruby
require 'ripper'
require 'pp'
require 'active_support/inflector' # String#pluralize  <-> String#singularize

# Abstraction of Model of MVC
module Abstraction
  module Parser
    # db/schema.rb
    class ModelSchema < Abstraction::Parser::AstParser

      def create_table(arg)
        $log.debug "create_table #{arg}"
        @modelname = ActiveSupport::Inflector.singularize(arg)
        # new Model state
        # n = 'M_' + @modelname
        @state = add_state('model', @modelname, @filename)
      end

      def add_attribute(type, name)
        $log.debug " attribute #{name} #{type}"
        # add to Variables[]
        n = @modelname + '#' + name
        v = add_variable('model', n, type, @filename)
        # link state<->variable
        v.state = @state
        @state.add_variable v
      end

      def parse_sexp(level, sexp)
        return if sexp.nil?

        if sexp[0].class == Symbol && sexp[0].to_s == 'command'
          cmd = sexp[1][1]
          arg = sexp[2][1][0][1][1][1]
          $log.debug "#{@indent.rjust(level)} #{level} command #{cmd} #{arg} =============="
          if cmd == 'create_table'
            create_table(arg)
            @create_table_true = true
            return
          end
          @create_table_true = false
        end

        if sexp[0].class == Symbol && sexp[0].to_s == '@ident'
          @type = sexp[1]
          $log.debug "#{@indent.rjust(level)} #{level} type #{@type} =============="
        end
        if sexp[0].class == Symbol && sexp[0].to_s == '@tstring_content' && @create_table_true
          attr = sexp[1]
          $log.debug "#{@indent.rjust(level)} #{level} attr #{attr} =============="
          add_attribute(@type, attr)
        end
        parse_sexp_common(level, sexp)
      end

      # Schema(Ruby) -> AST -> Abst
      def load(filename)
        @filename = filename
        $log.debug "ModelSchema.load #{filename}"
        @ruby = File.read(@filename)
        s = Ripper.sexp(@ruby)
        parse_sexp(0, s)
        add_variable('model', 'user#password', 'TBD', 'HELPER')
        add_variable('model', 'user#password_confirmation', 'TBD', 'HELPER')
      end
    end

    # add/models/*.rb
    class Model < Abstraction::Parser::AstParser
      # Model
      def parse_sexp(level, sexp)
        return if sexp.nil?
        @indent = ''
        if $parse_cancan
          # Ability.rb
          #  #$log.error "parse_sexp"
          #  #p sexp
          #  cancan_parse_sexp(level, sexp)
          #  parse_sexp_common(level, sexp)
          if sexp[0].class == Symbol
            symbol = sexp[0].to_s
            case symbol
            when 'class'
              return add_class(level, sexp, 'model')
            when 'def'
              return add_def(level, sexp, 'model')
            when 'command'
              # include
              return add_command(level, sexp, 'model')
            when 'if'
              $log.debug "CANCAN IF"
              return add_block(level, sexp, symbol)
            when 'elsif'
              return add_block(level, sexp, symbol)
            when 'else'
              return add_block(level, sexp, symbol)
            else
              $log.debug "Unknown symbol #{sexp[0].to_s} <============================ symbol"
            end
          end
        else
          # model/*.rb
          # devise list of func
          # attr_accessible list -> Model
          # has_many -> link to model
          if sexp[0].class == Symbol && sexp[0].to_s == 'command'
            return add_command(level, sexp, 'model')
          end
          if sexp[0].class == Symbol && sexp[0].to_s == 'class'
            return add_class(level, sexp, 'model')
          end
          if sexp[0].class == Symbol && sexp[0].to_s == 'def'
            # SKIP?
          end
        end
        parse_sexp_common(level, sexp)
      end

      # CANCAN
      # TODO: move to cancan.rb
      def cancan_parse_sexp(level, sexp)
        return if sexp.nil?
        @indent = ''

        $log.error "cancan_parse_sexp"
        p sexp

        if sexp[0].class == Symbol
          symbol = sexp[0].to_s
          case symbol
          when 'class'
            return add_class(level, sexp, 'model')
          when 'def'
            return add_def(level, sexp, 'model')
          when 'command'
            # include
            return add_command(level, sexp, 'model')
          when 'if'
            return add_block(level, sexp, symbol)
          when 'elsif'
            return add_block(level, sexp, symbol)
          when 'else'
            return add_block(level, sexp, symbol)
          else
            $log.error "Unknown symbol #{sexp[0].to_s} <============================ symbol"
          end
        end
        parse_sexp_common(level, sexp)
      end

      # Ruby -> AST by Ripper
      def load(modelname, filename)
        @modelname = modelname
        @filename = filename
        $log.debug "Model.load #{modelname} #{filename}"
        # clear flags
        $attr_accessible = nil
        $parse_cancan = false

        # check
        if $abst_states[@modelname].nil?
          if @modelname == 'M_ability'
            if $authorization == 'cancan'
              # ability is not listed in schema.rb, so add state here.
              $log.debug  "CANCAN #{@filename} start"
              # 2012/06/08 CanCan use ability model
              s = add_state('model', "ability", @filename)
              s.origin = 'auto(cancan)'
              $log.debug "added CanCan Ability model"
              # Set CanCan
              $parse_cancan = true
            else
              fail "#{modelname} is missing, check schema file. If the app is using CanCan, set,  $authorization = 'cancan'"
            end
          else
            $log.info "SKIP #{modelname} #{@filename}"
          end
        else
          $abst_states[@modelname].filename << @filename
        end

        $log.debug "load #{filename}"
        @ruby = File.read(@filename)
        s = Ripper.sexp(@ruby)
        parse_sexp(0, s)

        # Mass Assignment
        # $attr_accessible
        # $attr_accessible ["email", "password", "password_confirmation", "remember_me"]
        #                    model                                         lib/
        #                             Model - Device lib - DB
        unless $attr_accessible.nil?
          # look up the variable of this model
          # set flag attr_accessible = false
          list = get_ruby($attr_accessible).gsub(':', '').gsub(' ', '').split(',')
          if $state.nil?
            $log.error "missing state #{@filename}"
          else
            vs = $state.variables
            vs.each do |v|
              d = v.domain.split('#')
              v.attr_accessible = false
              list.each do |n|
                v.attr_accessible = true if n != '' && n == d[1]
              end
            end
          end
        end
        $log.debug "done"
      end # def
    end # class
  end # module
end # module
