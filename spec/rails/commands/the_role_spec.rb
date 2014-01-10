# -*- coding: UTF-8 -*-
#
# The_Role
# https://github.com/the-teacher/the_role
#
# rspec --color spec/rails/commands/the_role_spec.rb

require 'spec_helper'

require 'railroadmap/rails/abstraction'
require 'railroadmap/rails/the-role'

ruby_code_000 = <<"EOS"
class ApplicationController < ActionController::Base
  include TheRole::Controller

  protect_from_forgery

  def access_denied
    flash[:error] = t('the_role.access_denied')
    redirect_to(:back)
  end
end
EOS

ruby_code_100 = <<"EOS"
class PagesController < ApplicationController
  before_action :login_required, except: [:index, :show]
  before_action :role_required,  except: [:index, :show]

  #before_action :set_page,       only: [:edit, :update, :destroy]
  #before_action :owner_required, only: [:edit, :update, :destroy]

  def edit
     # ONLY OWNER CAN EDIT THIS PAGE
  end

  private

  #def set_page
  #  @page = Page.find params[:id]

    # TheRole: You should define OWNER CHECK OBJECT
    # When editable object was found
    # You should define @owner_check_object before invoking **owner_required** method
  #  @owner_check_object = @page
  #end
end
EOS

erb_code_200 = <<"EOS"
<% if @user.has_role?(:twitter, :button) %>
  Twitter Button is Here
<% else %>
  Nothing here :(
<% end %>
EOS
# >

describe Abstraction::Parser::View do

  it ": init railroadmap" do
    init_railroadmap
    $apv = Abstraction::Parser::View.new
    $apc = Abstraction::Parser::Controller.new
    $abs = Abstraction::MVC.new
    $abs.add_json_command_list('./lib/railroadmap/command_library/rails.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/the_role.json')

    $authorization_module = Rails::TheRole.new
  end

  it ": load controller code (ApplicationController)" do
    # load controller code
    sexp = Ripper.sexp(ruby_code_000)
    # $apc.set_modelname('task')
    # $apc.parse_sexp(0, sexp)
    # list_commands
    # pp $authorization_bf_list
    # pp $action_list
    # pp $abst_states
  end

  it ": load controller code (PagesController)" do
    # Controller
    $apc.set_modelname('page')

    # Routed actions
    $action_list['index'] = [0, nil]
    $action_list['create'] = [0, nil]
    $action_list['show'] = [0, nil]
    $action_list['edit'] = [0, nil]
    $action_list['update'] = [0, nil]

    # load controller code
    sexp = Ripper.sexp(ruby_code_100)
    $apc.parse_sexp(0, sexp)
    $apc.update_actions
    list_commands
    # list_states
    # pp $authorization_bf_list
    # pp $action_list
    # pp $abst_states
    pp $list_filter

    # Update AA

    $abst = Abstraction::MVC.new
    $abst.complete_filter

    # Update AA
    $authorization_module.pep_assignment
    list_states

    # check
    $abst_states['C_page#create'].code_policy.is_authorized.should eq nil
    $abst_states['C_page#show'].code_policy.is_authorized.should   eq nil
    $abst_states['C_page#index'].code_policy.is_authorized.should  eq nil
    $abst_states['C_page#edit'].code_policy.is_authorized.should   eq true
    $abst_states['C_page#update'].code_policy.is_authorized.should eq nil
  end
end
