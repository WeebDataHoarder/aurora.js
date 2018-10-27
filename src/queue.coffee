EventEmitter = require './core/events'

class Queue extends EventEmitter
    constructor: (@asset, options) ->
        @options = options || {}
        @readyMark = @options.readyMark || 64
        @finished = false
        @buffering = true
        @ended = false
        @maxQueueSize = @options.maxQueueSize || 0;

        @buffers = []
        @asset.on 'data', @write
        @asset.on 'end', =>
            @buffering = false
            @ended = true

        @asset.decodePacket()

    write: (buffer) =>
        @buffers.push buffer if buffer

        if @maxQueueSize
          while @buffers.length > @maxQueueSize
            @buffers.shift()

        if @buffering
            if @buffers.length >= @readyMark or @ended
                @buffering = false
                @emit 'ready'
            else
                @asset.decodePacket()

    read: ->
        return null if @buffering

        if @buffers.length is 0
          @buffering = true
          return null

        @asset.decodePacket()
        return @buffers.shift()

    reset: ->
        @buffers.length = 0
        @buffering = true
        @asset.decodePacket()

module.exports = Queue
