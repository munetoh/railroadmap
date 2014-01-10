# -*- coding: UTF-8 -*-
#
# CanCan
# https://github.com/ryanb/cancan
#
# rspec --color spec/rails/commands/cancan1_spec.rb
#
#
# load_and_authorize_resource -> AA all
#   list[all] = true
#
# load_and_authorize_resource :except => [:show]
#   list[all] = true
#   list[show] = except
#
# load_and_authorize_resource :only => [:show]
#   list[all] = false
#   list[show] = only
#
# load_and_authorize_resource
# skip_authorize_resource :only => :new
#   list[all] = true
#   list[new] = except

require 'spec_helper'

require 'railroadmap/rails/cancan'

ruby_code_010 = <<"EOS"
class TaskController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource
  def create
  end
  def show
  end
  def index
  end
  def edit
  end
  def update
  end
end
EOS

ruby_code_020 = <<"EOS"
class TaskController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :except => [:show]
  def create
  end
  def show
  end
  def index
  end
  def edit
  end
  def update
  end
end
EOS

ruby_code_030 = <<"EOS"
class TaskController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :only => [:edit, :update]
  def create
  end
  def show
  end
  def index
  end
  def edit
  end
  def update
  end
end
EOS

ruby_code_040 = <<"EOS"
class TaskController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource
  skip_authorize_resource :only => [:show,:index]
  def create
  end
  def show
  end
  def index
  end
  def edit
  end
  def update
  end
end
EOS

ruby_code_050 = <<"EOS"
class TaskController < ApplicationController
  before_filter :authenticate_user!
  def create
  end
  def show
    @task = Task.find(params[:id])
    authorize! :read, @task
  end
  def index
  end
  def edit
  end
  def update
  end
end
EOS

describe Abstraction::Parser::View do

  it ": init railroadmap" do
    init_railroadmap
    $apv = Abstraction::Parser::View.new
    $apc = Abstraction::Parser::Controller.new

    $abs = Abstraction::MVC.new
    $abs.add_json_command_list('./lib/railroadmap/command_library/rails.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/devise.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/cancan.json')

    $authorization_module = Rails::CanCan.new

    # Routed actions
    $action_list['create'] = [0, nil]
    $action_list['show'] = [0, nil]
    $action_list['index'] = [0, nil]
    $action_list['edit'] = [0, nil]
    $action_list['update'] = [0, nil]
  end

  it ": load controller code (load_and_authorize_resource)" do
    # load controller code
    sexp = Ripper.sexp(ruby_code_010)
    $apc.set_modelname('task')
    $apc.parse_sexp(0, sexp)
    # list_commands
    # pp $authorization_bf_list
    # pp $action_list
    # pp $abst_states

    # Update AA
    $authorization_module.pep_assignment
    # list_states

    # check
    $abst_states['C_task#create'].code_policy.is_authorized.should eq true
    $abst_states['C_task#show'].code_policy.is_authorized.should   eq true
    $abst_states['C_task#index'].code_policy.is_authorized.should  eq true
    $abst_states['C_task#edit'].code_policy.is_authorized.should   eq true
    $abst_states['C_task#update'].code_policy.is_authorized.should eq true
  end

  it ": load controller code (load_and_authorize_resource + except)" do
    # reset states
    $abst_states = {}
    $authorization_bf_list = {}
    $abst_commands = {}
    $abs.add_json_command_list('./lib/railroadmap/command_library/rails.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/devise.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/cancan.json')

    # load controller code
    sexp = Ripper.sexp(ruby_code_020)
    $apc.set_modelname('task')
    $apc.parse_sexp(0, sexp)
    # list_commands
    # pp $authorization_bf_list
    # pp $action_list
    # pp $abst_states

    # Update AA
    $authorization_module.pep_assignment
    # list_states

    # check
    $abst_states['C_task#create'].code_policy.is_authorized.should eq true
    $abst_states['C_task#show'].code_policy.is_authorized.should   eq false
    $abst_states['C_task#index'].code_policy.is_authorized.should  eq true
    $abst_states['C_task#edit'].code_policy.is_authorized.should   eq true
    $abst_states['C_task#update'].code_policy.is_authorized.should eq true
  end

  it ": load controller code (load_and_authorize_resource + only)" do
    # reset states
    $abst_states = {}
    $authorization_bf_list = {}
    $abst_commands = {}
    $abs.add_json_command_list('./lib/railroadmap/command_library/rails.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/devise.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/cancan.json')

    # load controller code
    sexp = Ripper.sexp(ruby_code_030)
    $apc.set_modelname('task')
    $apc.parse_sexp(0, sexp)
    # list_commands
    # pp $authorization_bf_list
    # pp $action_list
    # pp $abst_states

    # Update AA
    $authorization_module.pep_assignment
    # list_states

    # check
    $abst_states['C_task#create'].code_policy.is_authorized.should eq false
    $abst_states['C_task#show'].code_policy.is_authorized.should   eq false
    $abst_states['C_task#index'].code_policy.is_authorized.should  eq false
    $abst_states['C_task#edit'].code_policy.is_authorized.should   eq true
    $abst_states['C_task#update'].code_policy.is_authorized.should eq true
  end

  it ": load controller code (skip_authorize_resource)" do
    # reset states
    $abst_states = {}
    $authorization_bf = nil
    $authorization_bf_list = {}
    $abst_commands = {}
    $abs.add_json_command_list('./lib/railroadmap/command_library/rails.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/devise.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/cancan.json')

    sexp = Ripper.sexp(ruby_code_040)
    $apc.set_modelname('task')
    $apc.parse_sexp(0, sexp)
    # list_commands
    # pp $authorization_bf_list
    # pp $action_list
    # pp $abst_states

    # Update AA
    $authorization_module.pep_assignment
    # list_states

    # check
    $abst_states['C_task#create'].code_policy.is_authorized.should eq true
    $abst_states['C_task#show'].code_policy.is_authorized.should   eq false
    $abst_states['C_task#index'].code_policy.is_authorized.should  eq false
    $abst_states['C_task#edit'].code_policy.is_authorized.should   eq true
    $abst_states['C_task#update'].code_policy.is_authorized.should eq true
  end

  it ": load controller code (authorize!)" do
    # reset states
    $abst_states = {}
    $authorization_bf_list = {}
    $abst_commands = {}
    $abs.add_json_command_list('./lib/railroadmap/command_library/rails.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/devise.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/cancan.json')
    # pp $authorization_bf

    sexp = Ripper.sexp(ruby_code_050)
    $apc.set_modelname('task')
    $apc.parse_sexp(0, sexp)
    # pp sexp
    # list_commands
    # pp $authorization_bf
    # pp $authorization_bf_list
    # pp $action_list
    # pp $abst_states

    # Update AA
    $authorization_module.pep_assignment
    # list_states

    # check
    $abst_states['C_task#create'].code_policy.is_authorized.should eq nil
    $abst_states['C_task#show'].code_policy.is_authorized.should   eq true
    $abst_states['C_task#index'].code_policy.is_authorized.should  eq nil
    $abst_states['C_task#edit'].code_policy.is_authorized.should   eq nil
    $abst_states['C_task#update'].code_policy.is_authorized.should eq nil
  end
end
