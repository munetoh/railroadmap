require 'rubygems'
require 'rspec'

require 'rails/abstraction'

require 'pp'

# DEBUG
 require 'tracer'
# Tracer.on

describe Abstraction::Parser::View do
  
  # Setup
  it ": create global hash tables" do
    $abst_states = Hash.new
    $abst_transitions = Hash.new
    $abst_variables = Hash.new
    $abst_dataflows = Hash.new
  end
  
  it ": set global flags" do
    $protect_from_forgery = false    
    $verbose = 0
    $debug = false
    $robust = false
  end
  
    
  it ": Load the View (ERB) file and create abstraction model" do  
    #$debug = true

    # variables    
    s = Abstraction::Parser::ModelSchema.new
    s.load('./spec/rails/abstraction/sample/db/schema.rb')

    #     
    v1 = Abstraction::Parser::View.new
    v1.load('task',"./spec/rails/abstraction/sample/app/views/tasks/index.html.erb")
    #v1.abstract
    
    v2 = Abstraction::Parser::View.new
    v2.load('task',"./spec/rails/abstraction/sample/app/views/tasks/new.html.erb")
    #v2.abstract 

    v3 = Abstraction::Parser::View.new
    v3.load('task',"./spec/rails/abstraction/sample/app/views/tasks/show.html.erb")
    #v3.abstract 

    v4 = Abstraction::Parser::View.new
    v4.load('task',"./spec/rails/abstraction/sample/app/views/tasks/edit.html.erb")
    #v4.abstract

    #$debug = true
    #$verbose = 3
    v5 = Abstraction::Parser::View.new
    v5.load('task',"./spec/rails/abstraction/sample/app/views/tasks/_form.html.erb")
    #v5.abstract    

    if $verbose > 0 then
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
    $abst_states.size.should eq 9
    $abst_transitions.size.should eq 16
       
  end
  
  
  
  it ": compleate the abstraction model" do 
    $rspec_on = true
    a = Abstraction::MVC.new(nil)
    
    # refine block/condition
    # Condition (ruby) => Abst (B?)
    guard2abst = Hash.new 
    guard2abst[''] = ''
    a.guard2abst = guard2abst
    
    a.complete_block
    
    # refine transition
    
    # routes
    p2id = Hash.new    
    p2id['new_task_path']     = 'C_task#new'
    p2id['tasks_path']        = 'C_task#index'  
    p2id['edit_task_path']    = 'C_task#edit'  
    
    p2id['@task']             = 'C_task#show1'  # OR destroy
    
    #p2id['task']              = 'C_task#show2'
    p2id['tag']               = 'C_tag#index'
    
    # 
    p2id['registration_path'] = 'C_devise:registration#tbd'
    
    # TODO link_to :back
    p2id['back'] = 'C_caller'
    
    a.path2id = p2id
    
    a.complete_transition
    
    #$debug = false
    
    if $verbose > 0 then
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
    $abst_states.size.should eq 9
    $abst_transitions.size.should eq 16
    
  end
  
  
end