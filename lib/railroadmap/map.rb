# -*- coding: UTF-8 -*-
# Map
#
# - Conteiner for JSON in/out
#   ref
#    http://www.skorks.com/2010/04/serializing-and-deserializing-objects-with-ruby/
#    http://stackoverflow.com/questions/6879589/using-custom-to-json-method-in-nested-objects
#

require 'json'
#
# Class for Json import and export
#

require 'railroadmap/rails/abstraction'

# Map: JSON in out
class Map
  # init
  def initialize(gendate)
    @gendate = gendate
    @states = nil
    @transitions = nil
  end
  attr_accessor :states, :transitions, :marked_states

  # to S
  def to_s
    p @test
    p @state.count
    p @state["M_comment"].class
  end

  #
  # to JSON
  #
  def to_json(*a)
    {
      "json_class" => self.class.name,
      "data" => {
        "gendate" => @gendate,
        "states" => @states,
        "transitions" => @transitions
      }
    }.to_json(*a)
  end

  #
  # from JSON
  #
  def self.json_create(o)
    # new Object
    map = new(o["data"]["gendate"])
    map.states = {}
    s1 = o["data"]["states"]
    s1.each do |k, v|
      map.states.store(k, v)
    end
    map
  end
end

# State list
class StateList
  # init
  def initialize(*a)
    @abst_states = []
  end
  attr_accessor :abst_states

  # to JSON
  def self.to_json(*a)
    {
      "json_class"   => self.class.name,
      "data"         => { "list" => @abst_states }
    }.to_json(*a)
  end

  # to JSON
  def self.create_json(o)
    new(o["data"]["list"])
  end
end
