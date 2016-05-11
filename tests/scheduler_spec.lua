require('tests.bootstrap')(assert)

describe('scheduler', function()
    local scheduler
    local match = require 'luassert.match'

    before_each(function()
        scheduler = require 'nginx-metrix.scheduler'
    end)

    after_each(function()
        package.loaded['nginx-metrix.collectors'] = nil
        _G.ngx = nil
    end)

    it('attach_collector', function()
        scheduler.attach_collector({})
        assert.is_equal(0, length(scheduler.__private__.get_collectors()))

        scheduler.attach_collector({name='test', periodically=function() end})
        assert.is_equal(1, length(scheduler.__private__.get_collectors()))
    end)

    it('start', function()
        _G.ngx = mock({timer = mock({at = function() end}), log = function() end})

        stub.new(_G.ngx.timer, 'at').on_call_with(match._,match._,match._).returns(true, nil)

        scheduler.start()
        assert.spy(_G.ngx.timer.at).was.called(1)
        assert.spy(_G.ngx.log).was_not.called()
    end)

    it('handler', function()
        pending('Not implemented yet')
    end)
end)
