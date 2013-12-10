# -*- coding: UTF-8 -*-
#  rspec --color spec/rails/abstraction/block_spec.rb

require 'rubygems'
require 'rspec'
require 'pp'

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

# DEBUG
# require 'tracer'
# Tracer.on


describe Abstraction::Block do

  # Setup
  it ": create global hash tables" do
    $abst_states =      Hash.new
    $abst_transitions = Hash.new
    $abst_variables =   Hash.new
    $abst_dataflows =   Hash.new
  end

  it ": create global variables" do
    $verbose = 0
    #$verbose = 1
    #$verbose = 3
    $robust = false
  end

  # Test data, state and variables
  it ": create test data" do
    p = Abstraction::Parser::AstParser.new

    # state

    # variables
    p.add_variable('model',     'task',      'obj',    'app/model/task.rb')
    p.add_variable('model_att', 'task#name', 'string', 'model/hoge.rb')
    
    p.add_variable('devise', 'sign_in', 'boolean', 'model/hoge.rb')
    p.add_variable('devise', 'current_user', 'boolean', 'model/hoge.rb')
    
    p.add_variable('controller', 'user#new#@user', 'obj', 'app/controller/users_controller.rb')
    p.add_variable('controller', 'user#create#@user', 'obj', 'app/controller/users_controller.rb')
    p.add_variable('controller', 'user#edit#@user', 'obj', 'app/controller/users_controller.rb')
    p.add_variable('controller', 'user#update#@user', 'obj', 'app/controller/users_controller.rb')
  end

  #
  # TEST 1
  #
  it ": create root block object" do
    $block_root = Abstraction::Block.new
    $block_root.type = 'root'
    $block_root.id = 'C_user#edit_R'
    $block = $block_root  # set current block,  => root
  end

  it ": create child do block object" do
    ruby = "task.each"
    sexp = Ripper::sexp(ruby)
    $block = $block.add_child('do', sexp, nil)
  end  
    
  it ": create child if block object" do
    ruby = "sign_in"
    sexp = Ripper::sexp(ruby)
    $block = $block.add_child('if', sexp, nil)
  end  

  it ": create other elsif block object" do
    ruby = "user == \"hoge\""
    sexp = Ripper::sexp(ruby)
    $block.add('elsif', sexp, nil)
  end  
  
  it ": create other else block object" do
    $block.add('else', nil, nil)
  end

  #
  # complete_condition(tcond)
  #
  it ": complete condition" do
    guard2abst = Hash.new
    guard2abst['task.size > 0'] = 'task exist'
    guard2abst['sign_in == true'] = 'sign_in'

    guard2abst_byblk = Hash.new # TODO
    $block_root.complete_condition(nil, nil, guard2abst, guard2abst_byblk)
  end

  it ": print" do
    if $verbose > 0 then
      puts ''
      puts "Variables"
      $abst_variables.each do |n,v|
        v.print
      end
      puts "Transitions"
      $abst_transitions.each do |n,v|
        v.print
      end
      #$verbose = 2
      puts "Dataflows[#{$abst_dataflows.size}]"
      $abst_dataflows.each do |n,v|
        v.print
      end
      puts "Blocks"
      $block_root.print(0)
    end
  end

  #############################################################################
  # TEST 2
  # TFB app/controllers/users_controller.rb update
  it ": create root block object 2" do
    $block2_root = Abstraction::Block.new
    $block2_root.type = 'root'
    $block2_root.id = 'C_user#update_R'
    $block2 = $block2_root  # set current block,  => root   
  end

  it ": create child if block object" do
    ruby = "@user.update_attributes(params[:user])"
    sexp = Ripper::sexp(ruby)
    $block2 = $block2.add_child('if', sexp, nil)
  end

  it ": create other else block object" do
    $block2.add('else', nil, nil)
  end

  it ": complete condition" do
    guard2abst = Hash.new
    guard2abst['@user.update_attributes(params[:user]) == true'] = 'update == true'
    guard2abst_byblk = Hash.new # TODO
    $block2_root.complete_condition(nil, nil, guard2abst, guard2abst_byblk)
  end

  #
  it ": print BLOCK 2" do
    if $verbose > 0
      puts ""
      $verbose = 2
      puts "Blocks 2"
      $block2_root.print(0)
    end
  end

  #############################################################################
  # TEST 3
  # TFB app/controllers/users_controller.rb destroy
  it ": create root block object 3" do
    $block3_root = Abstraction::Block.new
    $block3_root.type = 'root'
    $block3_root.id = 'C_user#destroy_R'
    $block3 = $block3_root  # set current block,  => root
  end

  it ": complete condition" do
    guard2abst = Hash.new
    guard2abst_byblk = Hash.new # TODO
    $block3_root.complete_condition(nil, nil, guard2abst, guard2abst_byblk)
  end

  it ": print BLOCK 3" do
    if $verbose > 0
      puts ""
      $verbose = 2
      puts "Blocks 3"
      $block3_root.print(0)
    end
  end
end
