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
          case sexp[0]
          when :class
            return add_class(level, sexp, 'controller')
          when :def # action
            $has_transition_render = false
            add_def(level, sexp, 'action')
            if $state.is_private || $state.is_protected
              # skip
            elsif $state.routed
              # skip
            else
              # active action
              unless $has_transition_render
                # add render if dest exist
                dst_id = 'V_' + $state.domain
                if $abst_states[dst_id].nil?
                  # no dist
                else
                  $transition = add_transition('render_def4', $state.id, dst_id, nil, $guard, @filename)
                  $has_transition = true
                  $has_transition_render = true
                  $log.debug "#{$state.id} => #{dst_id} render? 4 added"
                end
              end
            end
            return
          when :command
            return add_command(level, sexp, 'controller')
          when :if
            return add_block(level, sexp, symbol)
          when :elsif
            return add_block(level, sexp, symbol)
          when :else
            return add_block(level, sexp, symbol)
          when :if_mod
            return add_block(level, sexp, symbol)
          when :unless # CANNOT support XX unless XX
            return add_block(level, sexp, symbol)
          when :method_add_block
            # clear possible flags
            $respond_to = false
            parse_sexp_common(level, sexp)
            return
          when :do_block
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
          when :call
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
          when :vcall  # from Ruby 1.9.3?
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
          when :method_add_arg
            return add_method_add_arg(level, sexp, 'controller')
          when :var_ref
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
        $modelname = modelname
        @filename = filename
        $filename = filename # as global

        # get the actions from route table
        # Hash  action: [type, state]
        # type
        #  0   routed
        #  1   routed + code
        #  2            code
        $action_list = {}
        $route_map.each do |k, v|
          d0 = k.split('#')
          model = d0[0]
          action = d0[1]
          $action_list[action] = [0, nil] if modelname == model
        end

        @ruby = File.read(@filename)
        sexp  = Ripper.sexp(@ruby)

        # init
        # View       : state = file
        # Controller : state = def
        $block_var = []
        $has_transition = false

        # parse
        parse_sexp(0, sexp)

        # disclose omitted controllers
        # check with routemap
        $action_list.each do |k, v|
          if v[0] == 0
            # no code, omitted controller
            # add state
            domain = @modelname + '#' + k
            dst_id = 'V_' + domain

            if $abst_states[dst_id].nil?
              # no V for C
            else
              # add state and trans
              s = add_state('controller', domain, @filename)
              unless s.nil?
                # lookup before_filters for this states
                fs =  get_filter_lists(k)
                unless fs.nil?
                  $log.debug "add_def() -  def #{k} - filter exist #{fs}"
                  s.before_filters = fs
                end
                v[1] = s
                s.routed = true
                $transition = add_transition('render_def4', $state.id, dst_id, nil, $guard, @filename)
              end
            end
          end
        end

        # Global filters => each action
        $authorization_module.pep_assignment unless $authorization_module.nil?
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
      end # def
    end
  end
end
