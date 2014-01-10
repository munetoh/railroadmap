# -*- coding: UTF-8 -*-
#
# TODO: v010 => v02X
#
#  rspec --color spec/rails/abstraction/view_spec.rb

require 'spec_helper'

describe Abstraction::Parser::View do

  it ": init railroadmap" do
    init_railroadmap
    $apv = Abstraction::Parser::View.new
    $abs = Abstraction::MVC.new
    $abs.add_json_command_list('./lib/railroadmap/command_library/ruby.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/rails.json')
    $abs.add_json_command_list('./lib/railroadmap/command_library/devise.json')
    # v023 memo
    # microformats_duration  Helper of TimeFliesBy

    # dummy states
    sc1 = $apv.add_state('controller', 'task#create', nil)
    sc2 = $apv.add_state('controller', 'task#update', nil)
  end

  it ": Load the View (ERB) file and create abstraction model" do
    # $debug = true

    $abst_transitions.size.should eq 0

    # setup variables from schema
    s1 = Abstraction::Parser::ModelSchema.new
    s1.load('./spec/rails/abstraction/sample/db/schema.rb')

    # V_task#index
    v1 = Abstraction::Parser::View.new
    v1.load('task', "./spec/rails/abstraction/sample/app/views/tasks/index.html.erb")
    # v1.abstract
    # V_task#index --link_to new_task_path
    # V_task#index --link_to task.title.presence || '-- No Title! --', task, :class => 'url'
    # V_task#index --link_to tag.name, tag, 'rel' => 'tag'
    # V_task#index --form_for/submit   switch_to_task_path

    # list_transisions
    $abst_transitions.size.should eq 4

    v2 = Abstraction::Parser::View.new
    v2.load('task', "./spec/rails/abstraction/sample/app/views/tasks/new.html.erb")
    # v2.abstract

    # list_transisions
    $abst_transitions.size.should eq 6

    v3 = Abstraction::Parser::View.new
    v3.load('task', "./spec/rails/abstraction/sample/app/views/tasks/show.html.erb")
    # v3.abstract

    v4 = Abstraction::Parser::View.new
    v4.load('task', "./spec/rails/abstraction/sample/app/views/tasks/edit.html.erb")
    # v4.abstract

    # $debug = true
    # $verbose = 3
    v5 = Abstraction::Parser::View.new
    v5.load('task', "./spec/rails/abstraction/sample/app/views/tasks/_form.html.erb")
    # v5.abstract

    if $verbose > 0
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
    $abst_states.size.should eq 11

    # pp $abst_transitions
    # list_transisions
    # $abst_transitions.size.should eq 16
    $abst_transitions.size.should eq 19

  end

  it ": compleate the abstraction model" do
    $rspec_on = true
    a = Abstraction::MVC.new

    # refine block/condition
    # Condition (ruby) => Abst (B?)
    guard2abst = Hash.new
    guard2abst[''] = ''
    a.guard2abst = guard2abst
    # a.complete_block

    # refine transition

    # routes
    p2id = Hash.new
    p2id['new_task_path']     = 'C_task#new'
    p2id['tasks_path']        = 'C_task#index'
    p2id['edit_task_path']    = 'C_task#edit'

    p2id['@task']             = 'C_task#show1'  # OR destroy

    # p2id['task']              = 'C_task#show2'
    p2id['tag']               = 'C_tag#index'

    #
    p2id['registration_path'] = 'C_devise:registration#tbd'

    # TODO: link_to :back
    p2id['back'] = 'C_caller'

    a.path2id = p2id

    a.complete_transition

    # $debug = false
    if $verbose > 0
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
    $abst_states.size.should eq 11
    # v010 $abst_transitions.size.should eq 16
    $abst_transitions.size.should eq 19
  end
end
