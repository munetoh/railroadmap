# -*- coding: UTF-8 -*-
#
# TODO: v010 => v02X
#

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

describe Abstraction::Parser::Model do

  it ": setup" do
    $abst_states = Hash.new
    $abst_transitions = Hash.new
    $abst_variables = Hash.new
    $abst_dataflows = Hash.new
    $route_map = {}
    $list_class = {}
    $abst_commands = {}
    $unknown_command = 0
    $abst_transitions_count = 0
    $abst_dataflows_count = 0
    # $errors ||= Errors.new

    $robust  = false
    $debug = false
    $verbose = 0
  end

  it ": Load the model files (db,app/models)" do
    s1 = Abstraction::Parser::ModelSchema.new
    s1.load('./spec/rails/abstraction/sample/db/schema.rb')

    m0 = Abstraction::Parser::Model.new
    m0.load('M_user', 'user', './spec/rails/abstraction/sample/app/models/user.rb')

    # $debug = true
    m1 = Abstraction::Parser::Model.new
    m1.load('M_task', 'task', './spec/rails/abstraction/sample/app/models/task.rb')

    # $debug = true
    m2 = Abstraction::Parser::Model.new
    m2.load('M_tag', 'tag', './spec/rails/abstraction/sample/app/models/tag.rb')

    m3 = Abstraction::Parser::Model.new
    m3.load('M_tag_task', 'tag_task', './spec/rails/abstraction/sample/app/models/tag_task.rb')

    if $verbose > 0
      $abst_states.each do |n, s|
        p n
        s.print
      end
      $abst_variables.each do |n, v|
        p n
        v.print
      end
    end

    $abst_states['M_tag_task'].should_not nil
    $abst_states['M_tag'].should_not nil
    $abst_states['M_task'].should_not nil
    $abst_states['M_user'].should_not nil

    # TODO: add
    $abst_variables['S_tag_task#user_id'].should_not nil

    # for devise
    $abst_variables['S_user#remember_me'].should_not nil
    $abst_variables['S_user#current_password'].should_not nil
  end
end
