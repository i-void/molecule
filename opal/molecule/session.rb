require 'promise'

module Molecule
  # Controls the session for client side
  class Session
    attr_writer :key

    def key
      @key ||= Molecule::Cookie.get(:_sid)
    end

    def request_key
      Molecule::PowerCable.send('Molecule/SessionStart') do |response|
        self.key = response[:data]
        Molecule::Cookie.set(:_sid, response[:data], 30.minutes)
      end
    end

    def destroy
      Molecule::Cookie.set(:_sid, nil, 1.second)
    end

    class << self
      @instance = nil

      def create
        promise = Promise.new
        if @instance
          promise.resolve @instance
        else
          @instance = new
          if @instance.key
            promise.resolve @instance
          else
            @instance.request_key.then { promise.resolve(@instance) }
          end
        end
        promise
      end
    end
  end
end