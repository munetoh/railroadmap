# -*- coding: UTF-8 -*-
#
# Devise
# https://github.com/plataformatec/devise
# https://github.com/plataformatec/devise/wiki/Example-Applications
# https://github.com/railsapps/rails3-devise-rspec-cucumber
# https://github.com/jayshepherd/devise_example
#
# rspec --color spec/rails/commands/devise_spec.rb

require 'spec_helper'
require 'railroadmap/rails/devise'

ruby_code_000 = <<"EOS"
class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :role_ids, :as => :admin
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me
end
EOS

ruby_code_001 = <<"EOS"
class UsersController < ApplicationController
  before_filter :authenticate_user!
end
EOS

# >

describe Abstraction::Parser::View do

  it ": init railroadmap" do
    init_railroadmap
    $apv = Abstraction::Parser::View.new
    $apc = Abstraction::Parser::Controller.new
    $apm = Abstraction::Parser::Model.new
    $abs = Abstraction::MVC.new
    $abs.add_json_command_list('./lib/railroadmap/command_library/rails.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/devise.json')

    $authentication_module = Rails::Devise.new

    # Routed actions
    $action_list['create'] = [0, nil]
    $action_list['show'] = [0, nil]
    $action_list['index'] = [0, nil]
    $action_list['edit'] = [0, nil]
    $action_list['update'] = [0, nil]
  end

  it ": load model and config devise" do
    # load model code
    sexp = Ripper.sexp(ruby_code_000)
    # $apm.set_modelname('task')
    $apm.parse_sexp(0, sexp)
    # list_commands
    # list_states

    # pp $authorization_bf_list
    # pp $action_list
    # pp $abst_states

    # list_variables
    $abst_variables['S_user#remember_me'].type.should eq 'devise'
    $abst_variables['S_user#current_password'].type.should eq 'devise'
    $abst_variables['S_devise#user_signed_in?'].type.should eq 'devise'

  end

  it ": load controller" do
    # load model code
    sexp = Ripper.sexp(ruby_code_001)
    # $apm.set_modelname('task')
    $apc.parse_sexp(0, sexp)
    list_commands
    list_states
    # pp $authorization_bf_list
    # pp $action_list
    # pp $abst_states

    # UAT?

  end
end
