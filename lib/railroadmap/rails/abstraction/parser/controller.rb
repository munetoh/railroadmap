# -*- coding: UTF-8 -*-
# Conttroller
#

require 'rubygems'
require 'erb/stripper'
require 'ripper'
require 'pp'
require 'active_support/inflector' # String#pluralize  <-> String#singularize

# Abstraction of View
module Abstraction
  module Parser
    # Controller of MVC
    class Controller < Abstraction::Parser::AstParser
      # 20130801 command version
      # TODO: can this move to command()?
      def check_sf(ident, sexp)
        if $abst_commands[ident].nil?
          $log.debug "unknown ident : #{ident} in #{@filename}"
          # raise "DEBUG"
        else
          $log.info "check_sf() TODO: #{ident} => HIT in #{@filename}"
          # Add trans
          if $abst_commands[ident].has_trans
            add_transition_by_command(ident, $state, $guard, sexp, @filename)
          end

          # run abstract()
          $abst_commands[ident].abstract(nil, nil, @filename)  # TODO: sexp?
        end
      end

      # Controller
      def parse_sexp(level, sexp)
        if sexp[0].class == Symbol
          symbol = sexp[0].to_s
          case symbol
          when 'class'
            return add_class(level, sexp, 'controller')
          when 'def'
            return add_def(level, sexp, 'action')
          when 'command'
            return add_command(level, sexp, 'controller')
          when 'if'
            return add_block(level, sexp, symbol)
          when 'elsif'
            return add_block(level, sexp, symbol)
          when 'else'
            return add_block(level, sexp, symbol)
          when 'if_mod'
            return add_block(level, sexp, symbol)
          when 'method_add_block'
            # clear possible flags
            $respond_to = false
            $has_transition = false if $has_transition != true  # TODO: BAD LOGIC to avoid sub  method_add_block
            parse_sexp_common(level, sexp)

            if $has_transition == false && $transition.nil?
              dst_id = 'V_' + $state.domain
              $transition = add_transition('render_def3', $state.id, dst_id, nil, $guard, @filename)
              $has_transition = true
            end
            return
          when 'do_block'
            # add block_var
            # TODO
            pblock = $block
            $block = $block.add_child('do', sexp[1], nil)

            #  respond_to do |format|
            if !sexp[1].nil? && sexp[1][0].to_s == 'block_var' && sexp[1][1][0].to_s == 'param'
              var = sexp[1][1][1][0][1]
              $block_var << var
              parse_sexp_common(level, sexp)
              # remove block_var
              $block_var.delete_if { |x| x == var }
              $block = pblock
              return
            else
              # TODO: ?
              # e.g. format.all do
              # unknown
            end
            parse_sexp_common(level, sexp)
            $block = pblock
            return
          when 'call'
            if !sexp[1].nil? && sexp[1][0].to_s == 'var_ref' && sexp[1][1][0].to_s == '@ident'
              var_ref         = sexp[1][1][1]
              ident           = sexp[3][1]
              $transition     = nil
              $xml_transition = nil
              parse_sexp_common(level, sexp)

              $log.debug "IGNORE format.xml " if ident == 'xml'
              return
            else
              # Unknown
              # $log.error "unknown call"
            end
          when 'vcall'  # from Ruby 1.9.3?
            if !sexp[1].nil? && sexp[1][0].to_s == 'var_ref' && sexp[1][1][0].to_s == '@ident'
              var_ref         = sexp[1][1][1]
              ident           = sexp[3][1]
              $transition     = nil
              $xml_transition = nil
              parse_sexp_common(level, sexp)

              $log.debug "IGNORE format.xml " if ident == 'xml'
              return
            elsif !sexp[1].nil? && sexp[1][0].to_s == '@ident'
              ident = sexp[1][1]
              $log.debug "vcall indent=#{ident}"
              check_sf(ident, sexp)
            else
              # Unknown
            end
          when 'method_add_arg'
            return add_method_add_arg(level, sexp, 'controller')
          when 'var_ref'
            # Until Ruby 1.9.2
            # TODO: add_var_ref()
            ident = sexp[1][1]
            check_sf(ident, sexp)
          else
            # $log.error "Unknown symbol #{sexp[0].to_s}"
          end
        end

        # TODO: variable for ERB
        # e.g. @user = current_user
        # Symbol assign
        parse_sexp_common(level, sexp)
      end

      # Load controller/*rb file
      # ruby => AST => abst model
      def load(modelname, filename)
        @modelname = modelname
        @filename = filename
        $filename = filename # as global

        @ruby = File.read(@filename)
        sexp  = Ripper.sexp(@ruby)

        # init
        # View       : state = file
        # Controller : state = def
        $block_var = []
        $has_transition = false

        # parse
        parse_sexp(0, sexp)
      end

      # Dump
      def print
        puts "block #{@filename}"
        $abst_states.each do |n, v|
          s = $abst_states[n]
          if s.filename[0] == @filename
            v.print_block
            puts ''
          end
        end
      end
    end
  end
end
