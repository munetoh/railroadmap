# -*- coding: UTF-8 -*-
require 'rubygems'
require 'rspec'

require 'railroadmap/rails/abstraction'

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

# Testing targets
#   lib/rails/abstraction.rb
#   lib/rails/abstraction/parser/controller.rb
#   lib/rails/abstraction/parser/ast.rb
#
describe Abstraction::Parser::Controller do

  # Setup
  it ": create global hash tables" do
    $abst_states =      Hash.new
    $abst_transitions = Hash.new
    $abst_variables =   Hash.new
    $abst_dataflows =   Hash.new
    $route_map = {}
    $list_class = {}
    $abst_commands = {}
    $unknown_command = 0
    $abst_transitions_count = 0
  end

  it ": set global flags" do
    $protect_from_forgery = false
    $verbose = 0
    $debug = false
    $robust = false
  end

  it ": Load the controller files (app/controllers)" do
    # $debug = true
    # $verbose = 3
    c0 = Abstraction::Parser::Controller.new
    c0.load('application0', './spec/rails/abstraction/sample/app/controllers/application_controller.rb')

    c1 = Abstraction::Parser::Controller.new
    c1.load('user', './spec/rails/abstraction/sample/app/controllers/users_controller.rb')
    $debug = false

    c2 = Abstraction::Parser::Controller.new
    c2.load('task', './spec/rails/abstraction/sample/app/controllers/tasks_controller.rb')
    $debug = false

    c3 = Abstraction::Parser::Controller.new
    c3.load('tag', './spec/rails/abstraction/sample/app/controllers/tags_controller.rb')
    $debug = false

    c4 = Abstraction::Parser::Controller.new
    c4.load('welcome', './spec/rails/abstraction/sample/app/controllers/welcome_controller.rb')

    c5 = Abstraction::Parser::Controller.new
    c5.load('devise:confirmation', './spec/rails/abstraction/sample/app/controllers/devise/confirmations_controller.rb')

    if $verbose > 0
      puts "    protect_from_forgery = #{$protect_from_forgery} [#{$protect_from_forgery_filename}]"
      puts "    authentication_method = #{$authentication_method}"
      puts "States"
      $abst_states.each do |n, s|
        s.print
      end

      puts "Transitions"
      $abst_transitions.each do |n, t|
        t.print
      end
    end

    # check
    $abst_states.size.should eq 25
    # $abst_transitions.size.should eq 33
    $abst_transitions.size.should eq 25

    # $protect_from_forgery.should eq true
    $protect_from_forgery.should eq false
    # $authentication_method.should eq 'devise'
  end
end
