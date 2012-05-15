require 'rubygems'
require 'rspec'

require 'rails/abstraction'

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
  end
  
  it ": set global flags" do
    $protect_from_forgery = false    
    $verbose = 0
    $debug = false
    $robust = false
  end
  
  it ": Load the controller files (app/controllers)" do
    # $debug = true
    c0 = Abstraction::Parser::Controller.new
    c0.load('application0', './spec/rails/abstraction/sample/app/controllers/application_controller.rb')
    #c0.dsl.each do |l|
    #  puts "#{l}"
    #end
    
    #$debug = true
    #$verbose = 3
    c1 = Abstraction::Parser::Controller.new
    c1.load('user', './spec/rails/abstraction/sample/app/controllers/users_controller.rb')
    $debug = false
    #c1.dsl.each do |l|
    #  puts "#{l}"
    #end    

    #$debug = true
    #$verbose = 3
    c2 = Abstraction::Parser::Controller.new
    c2.load('task', './spec/rails/abstraction/sample/app/controllers/tasks_controller.rb')
    $debug = false

    #$debug = true
    #$verbose = 3
    c3 = Abstraction::Parser::Controller.new
    c3.load('tag', './spec/rails/abstraction/sample/app/controllers/tags_controller.rb')
    $debug = false

    c4 = Abstraction::Parser::Controller.new
    c4.load('welcome', './spec/rails/abstraction/sample/app/controllers/welcome_controller.rb')   

    #$debug = true
    c5 = Abstraction::Parser::Controller.new
    c5.load('devise:confirmation', './spec/rails/abstraction/sample/app/controllers/devise/confirmations_controller.rb')   
    
    if $verbose > 0 then
      puts "    protect_from_forgery = #{$protect_from_forgery} [#{$protect_from_forgery_filename}]"
      puts "    authentication_method = #{$authentication_method}"
      puts "States"
      $abst_states.each do |n,s|
         s.print
      end
      
      puts "Transitions"
      $abst_transitions.each do |n,t|
         t.print
      end
    end
    
    # check
    $abst_states.size.should eq 25
    $abst_transitions.size.should eq 33
    
    $protect_from_forgery.should eq true
    $authentication_method.should eq 'devise'
        
  end
  
  
  
end