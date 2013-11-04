# -*- coding: UTF-8 -*-
module Abstraction
  # TODO: attack
  class Attack
    def initialize
      @type = nil
      @path = nil
      @trans = nil
      @result_message = nil
    end
    attr_accessor :type, :path, :trans, :result_message
  end
end
