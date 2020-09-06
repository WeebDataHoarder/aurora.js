#
# The AudioDevice class is responsible for interfacing with various audio
# APIs in browsers, and for keeping track of the current playback time
# based on the device hardware time and the play/pause/seek state
#

EventEmitter = require './core/events'

class AudioDevice extends EventEmitter
    constructor: (@sampleRate, @channels, options) ->
        @options = options || {}
        @playing = false
        @currentTime = 0
        @_lastTime = 0

    start: ->
        return if @playing
        @playing = true

        @device ?= AudioDevice.create(@sampleRate, @channels, @options)
        unless @device
            throw new Error "No supported audio device found."

        @_lastTime = @device.getDeviceTime()

        @_timer = setInterval @updateTime, 30
        @device.on 'refill', @refill = (buffer) =>
            @emit 'refill', buffer

    stop: ->
        return unless @playing
        @playing = false

        @device.off 'refill', @refill
        clearInterval @_timer

    destroy: ->
        @stop()
        @device?.destroy()

    seek: (@currentTime) ->
        @_lastTime = @device.getDeviceTime() if @playing
        @emit 'timeUpdate', @currentTime

    updateTime: =>
        time = @device.getDeviceTime()
        @currentTime += (time - @_lastTime) / @device.sampleRate * 1000 | 0
        @_lastTime = time
        @emit 'timeUpdate', @currentTime

    devices = []
    @register: (device, weight) ->
        devices.push([device, weight || 5])

    @create: (sampleRate, channels, options) ->
        device = @device()
        return device && new device(sampleRate, channels, options)

    @device: ->
        _devices = devices.sort((a, b) -> a[1] - b[1]).map((element) -> element[0])
        for device in _devices when device.supported
          return device

        return null

    @deviceSampleRate: ->
        device = @device()
        device.deviceSampleRate?()

module.exports = AudioDevice
