#
# Models2012 Evaluation
#
#  Devise
#
#  TimeFliesBy
#  20110904 501d5889cce532ce30748dc33f5f9b8a83c1db28  <= tested
#  20110915 088d1b34a86e3f6b977d3aa9f68892e07e595c96 
#  20110916 459688c9140f4168a2265d6e3ddb62df52d6213c  3.0 -> 3.1  app/c/user removed,  added asset

require 'rubygems'
require 'rspec'

require 'rails/abstraction'

require 'pp'

begin
require './spec/rails/abstraction/testenv'
rescue LoadError=> e
  $stderr.puts e.message
  $stderr.puts "create `testenv.rb` file to set"
  exit e.status_code
end

# DEBUG
# require 'tracer'
# Tracer.on

describe Abstraction::MVC do
  
  it ": global variables " do
    $verbose = 0
    #$verbose = 1  # no filename
    #$verbose = 2
    $robust = false
    
    # Config diagram
    $bsd_display_layout = false
    #$bsd_display_layout = true
  end
  
  
  it ": Load MVC timefliesby " do
    
    a = Abstraction::MVC.new($timefliesby_basedirs)
    
    #
    # Add Variables
    #
    p = Abstraction::Parser::AstParser.new
    p.add_variable('devise', 'devise#user_signed_in?', 'string', 'model/hoge.rb')
    # TODO add this app/model/user
    #  devise :database_authenticatable, :registerable, #:encryptable,
    #     :recoverable, :rememberable, :trackable, :validatable,
    #     :confirmable, :lockable, :token_authenticatable
    #
    #p.add_variable('devise', 'user#remember_me', 'boolean', 'model/hoge.rb')
    
    a.load

    # TODO
    $use_devise = true
    
    # Dump 
    #$debug = true
    if $verbose > 0 then
      a.print_stat
    end
      
    # TODO missing submit => test at view_spec
    
    
    # Add trans to layout
    # TODO V_welcome#index -> V_layout#application
    p = Abstraction::Parser::AstParser.new
    
    # Layout
    p.add_transition('layout', 'V_welcome#index', 'V_layout#application', nil, nil, nil)
    
    # TODO redirect to origin. need variable
    p.add_transition('layout', 'C_devise:session#create', 'V_welcome#index', nil, nil, nil)
    
    
    # routes map
    a.path2id = {
      'new_user_session_path'      => 'C_devise:session#new',
      'user_session_path'          => 'C_devise:session#create',
      'destroy_user_session_path'  => 'C_devise:session#destroy',
    
      'user_password_path'       => 'C_devise:password#create',
      'new_user_password_path'   => 'C_devise:password#new',
      'edit_user_password_path'  => 'C_devise:password#edit',
    
      'cancel_user_registration_path'  => 'C_devise:registration#cancel',
      'user_registration_path'         => 'C_devise:registration#create',
      'new_user_registration_path'     => 'C_devise:registration#new',
      'edit_user_registration_path'    => 'C_devise:registration#edit',
    
      'user_confirmation_path'      => 'C_devise:confirmation#create',
      'new_user_confirmation_path'  => 'C_devise:confirmation#new',
    
      'user_unlock_path'      => 'C_devise:unlock#create',
      'new_user_unlock_path'  => 'C_devise:unlock#new',
    
      'user_path'      => 'C_user#create',  # POST
      'new_user_path'  => 'C_user#new',
      'edit_path'      => 'C_user#edit',
    
    
      'tasks_path'      => 'C_task#index',
      'tasks_url'       => 'C_task#index',
      'new_task_path'   => 'C_task#new',
      'edit_task_path'  => 'C_task#edit',
      'task_path'       => 'C_task#show',
            
      'tags_path'      => 'C_tag#index',
      'tags_url'       => 'C_tag#index',
      'new_tag_path'   => 'C_tag#new',
      'edit_tag_path'  => 'C_tag#edit',
      'tag_path'       => 'C_tag#show',
    
      'root'       => 'C_welcome#index',
      'root_path'  => 'C_welcome#index',
      'root_url'   => 'C_welcome#index',

    # HELP
      '@tag'      => 'C_tag#show',
      'tag'       => 'C_tag#show',
      '@task'     => 'C_task#show',
      'task'      => 'C_task#show',
    
    # TODO HELP redirect_to with Helper
      'new_registration_path'             => 'C_devise:registration#new',
      'after_omniauth_failure_path_for'   => 'C_welcome#index',
      'redirect_location'                 => 'C_welcome#index',
      'after_sign_out_path_for'           => 'C_welcome#index',
    
    # TODO switch_to_task_path(task) tasks/index.html
      'switch_to_task_path'         => 'C_task#switch_to',
    
    # TODO 
      'registration_path'           => 'C_devise:registration#unknown',
    
      'confirmation_url'            => 'C_devise:confirmation#unknown',
      'new_confirmation_url'        => 'C_devise:confirmation#new',
      'new_confirmation_path'       => 'C_devise:confirmation#new',
      'edit_password_url'           => 'C_devise:password#edit',
      'new_password_path'           => 'C_devise:password#new',
      'new_session_path'            => 'C_devise:session#new',
      'new_unlock_path'             => 'C_devise:unlock#new',
      'unlock_url'                  => 'C_devise:unlock#new',
      'omniauth_authorize_path'     => 'C_devise:omniauth_callback#unknown',
    
    # Pseudo state
      'back'  => 'C_caller',
      'stored_location_for'  => 'C_welcome#index', # TODO
    }
    #a.set_pathmap(path2id)
    
    # Guard: Ruby to Abst
    
    
    
    
    vmap ={
      'devise#user_signed_in?' => ['boolean','signed_in'],
    }
    a.set_variable_abstmap(vmap)
    
    
    
    # refine block/condition
    # Condition (ruby) => Abst (B?)
    guard2abst = {
      '' => '',
      '|format|.size > 0' => 'true',
      '@tag.save == true'                              => 'save==true',
      '@tag.update_attributes(params[:tag]) == true'   => 'update==true',
      '@task.save == true'                             => 'save==true',
      '@task.update_attributes(params[:task]) == true' => 'update==true',
      '@user.save == true'                             => 'save==true',
      '@user.update_attributes(params[:user]) == true' => 'update==true',
      'resource.errors.empty? == true'                 => 'post_error==true',
      'resource.save == true'                          => 'save==true',
      'resource.update_with_password(params[resource_name]) == true' => 'update==true',
      'successful_and_sane?(resource) == true' => 'resource==true',
      'controller_name!="sessions" == true'    => 'TBD', # 'not session controller',
      'devise_mapping.registerable?&&controller_name!="registrations" == true' => 'TBD',
      'devise_mapping.recoverable?&&controller_name!="passwords" == true'      => 'TBD',
      'devise_mapping.confirmable?&&controller_name!="confirmations" == true'  => 'TBD',
      'devise_mapping.lockable?&&resource_class.unlock_strategy_enabled?(:email)&&controller_name!="unlocks" == true' => 'TBD',
      'devise_mapping.omniauthable? == true' => 'TBD',
      'user_signed_in? == true'   => 'signed_in==true',
      '@task.new_record? == true' => 'update==true',
    }
    a.set_guard_abstmap(guard2abst)
    
    action2abst = {
      #'V_devise:session#new_R' => 'sign_in = authentication(user,password,password_confirmation)',
      'V_devise:session#new_R'       => 'signed_in = true',
      'C_devise:session#destroy_R_D' => 'signed_in = false'
    }
    a.set_action_abstmap(action2abst)
    
    
    # Submit variable <=> SETS in B
    $map_bset_types = {
      'email' => 'EMAIL',
      'password' => 'PASSWORD',
      'password_confirmation' => 'PASSWORD',
      'current_password' => 'PASSWORD',
      'remember_me' => 'FLAG',
      'title' => 'TEXT',
      'description' => 'TEXT',
      'reset_password_token' => 'FLAG',
      'name' => 'TEXT'
    }
    
    
    a.complete_block
    # refine transition
    a.complete_transition
    
    
    # Dump 
    if $verbose > 0 then
      $debug = true
      a.print_stat
    end
        
    # Graphviz
    #a.png('output/abstraction_spec_timeflyesby.png')
    
    #a.graphviz('output/timefliesby')
    #a.html('output', nil)
    #
    Dir::mkdir("output") if File.exists?("output") == false
    Dir::mkdir("output/timefliesby") if File.exists?("output/timefliesby") == false

    h = Abstraction::Output::Html5.new
    h.html('output/timefliesby', nil)
    
    # B method
    # probcli output/timefliesby/railroadmap.mch -c
    # prob output/timefliesby/railroadmap.mch
    b = Abstraction::Output::Bmethod.new
    b.output('output/timefliesby')
    
  end
end