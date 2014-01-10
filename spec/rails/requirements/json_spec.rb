# -*- coding: UTF-8 -*-
#
# rspec --color spec/rails/requirements/json_spec.rb
#

require 'spec_helper'
require 'railroadmap/rails/requirement'
require 'railroadmap/rails/devise'
require 'railroadmap/rails/cancan'
require 'railroadmap/rails/the-role'
require 'railroadmap/rails/abstraction'

describe Rails::Requirement do

  it ": sample requirements" do
    req = Rails::Requirement.new
    $authentication_module = nil
    $authorization_module = nil
    $abst_states = {}

    # save
    filename = '/tmp/railroadmap_json_spec_001.json'
    req.print_sample_requirements(filename)

    # load
    open(filename, 'r') { |fp| @requirements_hash = JSON.parse(fp.read) }
    # pp @requirements_hash
    @requirements_hash['roles']['admin']['level'].should eq 10
  end

  it ": sample requirements w/ Devise + CanCan" do
    req = Rails::Requirement.new
    $path2id = {}
    $authentication_module = Rails::Devise.new
    $authorization_module = Rails::CanCan.new
    $abst_states = {}

    # save
    filename = '/tmp/railroadmap_json_spec_002.json'
    req.print_sample_requirements(filename)

    # load
    open(filename, 'r') { |fp| @requirements_hash = JSON.parse(fp.read) }
    # pp @requirements_hash

    # Devise
    @requirements_hash['asset_base_policies']['user']['model_alias']['devise:registration'].should eq 'user'
    @requirements_hash['asset_base_policies']['user']['level'].should eq 10
    # CanCan
    @requirements_hash['asset_base_policies']['ability']['level'].should eq 15
  end

  it ": sample requirements w/ Devise + The_Role" do
    req = Rails::Requirement.new
    $path2id = {}
    $authentication_module = Rails::Devise.new
    $authorization_module = Rails::TheRole.new
    $abst_states = {}

    # Add model
    $ast = Abstraction::Parser::Model.new
    $ast.add_state('model', 'task', nil)

    # save
    filename = '/tmp/railroadmap_json_spec_003.json'
    req.print_sample_requirements(filename)

    # load
    open(filename, 'r') { |fp| @requirements_hash = JSON.parse(fp.read) }
    # pp @requirements_hash
    @requirements_hash['asset_base_policies']['role']['model_alias']['admin:role'].should eq 'role'
    @requirements_hash['asset_base_policies']['task']['is_authenticated'].should eq true
    # Model

    # JSON
    # "roles": [
    #  { "role": "moderator", "action": "CRUD" },
    #  { "role": "user",  "action": "CRU", "is_owner": true } ]
    @requirements_hash['asset_base_policies']['user']['roles'][0]['role'].should eq 'admin'
  end

  it ": sample requirement for discrete state" do
    # Add C state
    $abst_states = {}
    $route_map = {}
    $ast = Abstraction::Parser::Controller.new
    state = $ast.add_state('controller', 'task#show', nil)

    req = Rails::Requirement.new
    filename = '/tmp/railroadmap_json_spec_004.json'
    req.add_discrete_requirement(state)
    req.print_discrete_requirement(filename)

    # load
    open(filename, 'r') { |fp| @requirements_hash = JSON.parse(fp.read) }
     pp @requirements_hash
    @requirements_hash['asset_discrete_policies']['C_task#show']['is_authenticated'].should eq false
  end
end
