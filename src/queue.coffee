EventEmitter = require './core/events'

class Queue extends EventEmitter
    constructor: (@asset, options) ->
        @options = options || {}
        @readyMark = @options.readyMark || 64
        @finished = false
        @buffering = true
        @ended = false
        @maxQueueSize = @options.maxQueueSize || 0;
        @available = 0

        @buffers = []
        @asset.on 'data', @write
        @asset.on 'end', =>
            @buffering = false
            @ended = true

        @asset.decodePacket()

    write: (buffer) =>
        if buffer
            @buffers.push buffer
            @available += buffer.length

        if @maxQueueSize
            while @buffers.length > @maxQueueSize
                toRemove = @buffers.shift()
                @available -= toRemove.length

        if @buffering
            if @buffers.length >= @readyMark or @ended
                @buffering = false
                @emit 'ready'
                @emit 'data'
            else
                @asset.decodePacket()
        else
          @emit 'data'

    read: ->
        return null if @buffering

        if @buffers.length is 0
            @buffering = true
            return null

        @asset.decodePacket()
        packet = @buffers.shift()
        @available -= packet.length

        packet

    reset: ->
        @buffers.length = 0
        @available = 0
        @buffering = true
        @asset.decodePacket()

module.exports = Queue
