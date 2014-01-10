# -*- coding: UTF-8 -*-

require 'rubygems'
require 'rspec'

require 'railroadmap/rails/abstraction'
require 'railroadmap/errors.rb'
require 'railroadmap/warning.rb'

require 'pp'

# Logging
require 'logger'
$log = Logger.new(STDOUT)
$log.level = Logger::ERROR
$log.formatter = proc do |severity, datetime, progname, msg|
  if severity == 'ERROR' || severity == 'INFO' || severity == 'DEBUG'
    position = caller.at(4).sub(%r{.*/}, '').sub(%r{:in\s.*}, '')
    "#{severity} #{position} #{msg}\n"
  else
    "#{severity} #{msg}\n"
  end
end

# Helper
module RailsHelper
  def init_railroadmap
    # Global
    $block_var = []
    $abst_commands = {}
    $unknown_command = 0

    $abst_states = {}
    $abst_transitions = {}
    $abst_transitions_count = 0

    $route_map = {}

    $path2id = {}
    $abst_dataflows = {}
    $abst_dataflows_count = 0

    $abst_variables = {}

    $list_class = {}
    $action_list = {}
    $list_global_filter = {}

    $protect_from_forgery = false
    $verbose = 0
    $debug = false
    $robust = false
    $enable_stdout = false
    # $enable_stdout = true

    $xss_raw_count = 0
    $xss_raw_region = false
    $xss_raw_files = []

    $is_protected = false
    $is_private = false

    $warning = Warning.new
    $errors = Errors.new
  end

  #
  #  C_task#edit
  #    render
  #  V_task#edit
  #    submit
  #  C_task#update
  #    render
  #  V_task#show
  #
  #  S_task#version
  #  S_task#author
  def create_dummy_mvc_for_injection_test
    init_railroadmap
    $ast = Abstraction::Parser::View.new
    $astc = Abstraction::Parser::Controller.new
    $abs = Abstraction::MVC.new
    $abs.add_json_command_list('./lib/railroadmap/command_library/rails.json')

    # variables
    $ast.add_variable('model', 'task#version', 'TBD', 'DUMMY')
    $ast.add_variable('model', 'task#author', 'TBD', 'DUMMY')

    # Controler 1
    sc1 = $ast.add_state('controller', 'task#edit',   nil)

    # Views1
    erb_code1 = <<"EOS"
<%= form_for @task do |f| %>
  <%= f.label :version, 'Version' %>: <%= f.text_field :version %><br />
  <%= f.label :author, 'Author' %>: <%= f.text_field :author %><br />
  <%= f.submit %>
<% end %>
EOS

    $state = $ast.add_state('view', 'task#edit', nil)
    ruby_code = Erb::Stripper.new.to_ruby(erb_code1)
    sexp = Ripper.sexp(ruby_code)
    $ast.parse_sexp(0, sexp)
    # pp $abst_transitions
    # list_transisions
    $abst_transitions_count.should eq 1

    # Controller2
    sc2 = $ast.add_state('controller', 'task#update', nil)

    # Views2
    erb_code2 = <<"EOS"
<%= label :version, 'Version' %>: <%= raw version %><br />
<%= f.label :author, 'Author' %>: <%= h author %><br />
EOS

    $state = $ast.add_state('view', 'task#show', nil)
    ruby_code = Erb::Stripper.new.to_ruby(erb_code2)
    sexp = Ripper.sexp(ruby_code)
    $ast.parse_sexp(0, sexp)
    # pp $abst_commands
    # pp $abst_transitions
    # list_transisions
    $abst_transitions_count.should eq 1

    # Trans: Controller1 to Views1
    $ast.add_transition('render', 'C_task#edit', 'V_task#edit', nil, nil, nil)
    # Trans: Controller2 to Views2
    $ast.add_transition('render', 'C_task#update', 'V_task#show', nil, nil, nil)

    $abst_transitions_count.should eq 3
    # list_transisions
    # list_commands
  end

  def list_states
    if $abst_states.size == 0
      puts "no states"
    else
      puts ""
      $abst_states.each do |k, s|
        a1 = '_'
        a1 = 'A' if  s.code_policy.is_authenticated
        a2 = '_'
        a2 = 'A' if  s.code_policy.is_authorized

        puts "#{k.rjust(16)} xss #{s.xss_out} PEP=#{a1}#{a2}"
      end
    end
  end

  def list_transitions
    if $abst_transitions.size == 0
      puts "no transitions"
    else
      puts ""
      $abst_transitions.each do |k, t|
        if !t.authentication_filter.nil?
          if !t.authorization_filter.nil?
            aa = 'AA'
          else
            aa = 'A_'
          end
        elsif !t.authorization_filter.nil?
          aa = '_A'
        else
          aa = '__'
        end
        puts "#{k} #{t.type} #{t.src_id} #{t.dst_id} PEP=#{aa}"
      end
    end
  end

  def list_dataflows
    if $abst_dataflows.size == 0
      puts "no dataflows"
    else
      puts ""
      $abst_dataflows.each do |k, df|
        puts "#{k} #{df.type} #{df.subtype} src=#{df.src_id}. dst=#{df.dst_id}"
      end
    end
  end

  def list_commands
    if $abst_commands.size == 0
      puts "no commands"
    else
      puts ""
      $abst_commands.each do |k, c|
        puts "#{k} #{c.count}, is_sf=#{c.is_sf}, sf_type=#{c.sf_type}  status=#{c.status}" if c.count > 0
      end
    end
  end

  def list_variables
    if $abst_variables.size == 0
      puts "no variables"
    else
      puts ""
      $abst_variables.each do |k, v|
        puts "#{k} #{v.type}"
      end
    end
  end

  def list_warnings
    if $warning.nil?
      puts "no warning"
    else
      $warning.warnings.each do |k, w|
        puts "  #{k} #{w['warning_type']}"
      end
    end
  end
end
