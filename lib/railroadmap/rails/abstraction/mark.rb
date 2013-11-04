# -*- coding: UTF-8 -*-
#
#  Mark of state that may have a weakness
#  Annotation? Flag?
#
# TODO: any good name
#
# Brakeman

module Abstraction
  # Mark
  class Mark
    #  Type
    #    Brakeman
    #    Security Functions
    def initialize(type)
      @type = type
      @attack_type = ''

      # Brakeman
      @brakeman_type = ''
      @brakeman_message = ''
      @brakeman_line = 0
    end
    attr_accessor :type, :attack_type,
                  :brakeman_type, :brakeman_message, :brakeman_line

    # JSON export
    def to_json(*a)
      {
        "json_class"   => self.class.name, #
        "data"         => {
          "type" => @type,
          "attack_type" => @attack_type,
          # Brakeman
          "brakeman_type" => @brakeman_type,
          "brakeman_message" => @brakeman_message,
          "brakeman_line" => @brakeman_line,
        }
      }.to_json(*a)
    end

    # JSON import
    def self.json_create(o)
      s = new(o["data"]["type"])
      # Location
      s.attack_type = o["data"]["attack_type"]
      # Brakeman
      s.brakeman_type = o["data"]["brakeman_type"]
      s.brakeman_message = o["data"]["brakeman_message"]
      s.brakeman_line = o["data"]["brakeman_line"]
      return s
    end

    def brakeman(type, massage, line)
      @brakeman_type = type
      @brakeman_message = massage
      @brakeman_line = line
    end
  end
end
