# -*- coding: UTF-8 -*-
#  Command object
#
#  MVC code ---> command ---> framework
#                        ---> helper
#                        ---> library
#
#
#  $abst.command['command name'] = Command
#
#  name:  command name (string)
#  body:
#  type:
#    transition
#
#  is_security_function
#    true
#    false
#    TODO: how to handle hidden/Implict/Default functions => e.g. h, escape
#
#  Usage
#     lib/cli.rb
#
# Abstraction:Command
require 'sorcerer'

module Abstraction
  # base class for command
  class Command < Abstraction::Parser::AstParser
    def initialize
      @name = nil
      @body = nil

      @type    = 'unknown'     # transition | dataflow | filter
      @subtype = 'unknown'  # render | link_to ...

      # Transitions
      @has_trans = false
      @transition_path = nil

      @has_dataflow = false
      @is_inbound   = false # dataflow with submit(post)
      @is_outbound  = false

      @is_sf   = false
      @sf_type = nil

      @testcase_type = nil
      @testcase_name = nil

      @count      = 0
      @providedby = 'unknown'  # rails | devise | cancan | app
      @filenames  = []
      @unclear    = true
      @comment    = ''
      @status     = 'beta'     # abstracted beta alpha unkown

      # user provided DST list => extracted by compleate_filter() and abstract_filter()
      @dst_table = nil

      # used at
      @location_list = []
    end
    attr_accessor :name, :has_trans, :has_dataflow, :is_inbound, :is_outbound,
                  :is_sf, :sf_type, :testcase_type, :testcase_name,
                  :count, :type, :subtype, :providedby,
                  :filenames, :unclear, :comment, :status, :dst_table,
                  :transition_path, :location_list

    # callback
    def abstract(sexp, sarg, filename)
      @count += 1
      @filenames << filename

      # update flags by GLOBAL security filter
      $protect_from_forgery = true if @is_sf && @sf_type == 'csrf'
    end

    # callback
    def abstract_filter(state)
      $log.debug "abstract_filter() TODO: #{state.id} #{@name}"

      unless @dst_table.nil?
        # add transitions
        $log.debug "abstract_filter() TODO: #{state.id} #{@name} HAS TRANS"
        @dst_table.each do |dst|
          path = dst['dest_path']
          dst_id = $path2id[path]

          $log.debug "abstract_filter() TODO: #{state.id} #{@name} HAS TRANS #{state.id} => #{path}, #{dst_id} "

          t = add_transition(dst['transitionType'], state.id, dst_id, nil, dst['guard'], @filename)
          if t.nil?
            # TODO: only apply active controller state
            $log.error "abstract_filter() - add_transition( #{state.id}, #{dst_id} ) failed"
          else
            # TODO: message
            t.messages = dst['messages']
            t.comment = "added by before_filter #{@name}"
            $filter_added_trans_count += 1
          end
        end
        # TODO: count added trantitions
      end
    end

    # TODO: arg => dest_path
    def get_dest(sexp)
      return nil
    end
  end
end
