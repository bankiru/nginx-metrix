require('tests.bootstrap')(assert)

describe('scheduler', function()
    local scheduler
    local logger
    local match

    setup(function()
        logger = mock(require 'nginx-metrix.logger', true)
        match = require 'luassert.match'

        _G.ngx = {
            timer = {
                at = function() end,
            },
            thread = {
                spawn = function() end,
                wait = function() end,
            },
        }
    end)

    teardown(function()
        package.loaded['nginx-metrix.logger'] = nil
        _G.ngx = nil
    end)

    before_each(function()
        mock(_G.ngx)

        scheduler = require 'nginx-metrix.scheduler'
    end)

    after_each(function()
        package.loaded['nginx-metrix.scheduler'] = nil
        mock.clear(logger)
        mock.revert(_G.ngx)
    end)

    it('attach_collector', function()
        scheduler.attach_collector({})
        assert.is_equal(0, length(scheduler.__private__.get_collectors()))

        scheduler.attach_collector({name='test', periodically=function() end})
        assert.is_equal(1, length(scheduler.__private__.get_collectors()))
    end)

    it('start failed', function()
        stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), {}).returns(false, 'test error')

        assert.is_false(scheduler.start())
        assert.spy(_G.ngx.timer.at).was.called_with(1, match.is_function(), {})
        assert.spy(_G.ngx.timer.at).was.called(1)
        assert.spy(logger.error).was.called_with('Failed to start the scheduler - failed to create the timer: ', 'test error')
        assert.spy(logger.error).was.called(1)
    end)

    it('start without collectors', function()
        stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), {}).returns(true, nil)

        assert.is_true(scheduler.start())
        assert.spy(_G.ngx.timer.at).was.called(1)
        assert.spy(logger.error).was_not.called()
    end)

    it('start with collectors', function()
        local test_collector = {name='test', periodically=function() end}
        scheduler.attach_collector(test_collector)

        stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), {test_collector}).returns(true, nil)

        assert.is_true(scheduler.start())
        assert.spy(_G.ngx.timer.at).was.called_with(1, match.is_function(), {test_collector})
        assert.spy(_G.ngx.timer.at).was.called(1)
        assert.spy(logger.error).was_not.called()
    end)

    it('handler on premature call', function()
        local test_collector = mock({name='test', periodically=function() end})
        scheduler.__private__.handler(true, {test_collector})
        assert.spy(_G.ngx.thread.spawn).was_not.called()
        assert.spy(_G.ngx.thread.wait).was_not.called()
        assert.spy(_G.ngx.timer.at).was_not.called()
        assert.spy(logger.error).was_not.called()
    end)

    it('handler failed to start next iter', function()
        stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), {}).returns(false, 'test error')

        scheduler.__private__.handler(false, {})

        assert.spy(_G.ngx.thread.spawn).was_not.called()
        assert.spy(_G.ngx.thread.wait).was_not.called()
        assert.spy(_G.ngx.timer.at).was.called_with(1, match.is_function(), {})
        assert.spy(_G.ngx.timer.at).was.called(1)
        assert.spy(logger.error).was.called_with('Failed to continue the scheduler - failed to create the timer: ', 'test error')
        assert.spy(logger.error).was.called(1)
    end)

    it('handler without collectors', function()
        stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), {}).returns(true, nil)

        scheduler.__private__.handler(false, {})

        assert.spy(_G.ngx.thread.spawn).was_not.called()
        assert.spy(_G.ngx.thread.wait).was_not.called()
        assert.spy(_G.ngx.timer.at).was.called_with(1, match.is_function(), {})
        assert.spy(_G.ngx.timer.at).was.called(1)
        assert.spy(logger.error).was_not.called()
    end)

    it('handler log error if can not wait thread', function()
        local test_collector = mock({name='test', periodically=function() end})
        local thread = {[[thread stub]]}

        stub.new(_G.ngx.thread, 'spawn').on_call_with(match.is_function()).returns(thread)
        stub.new(_G.ngx.thread, 'wait').on_call_with(thread).returns(false, 'test error')
        stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), {test_collector}).returns(true, nil)

        scheduler.__private__.handler(false, {test_collector})

        assert.spy(_G.ngx.thread.spawn).was.called_with(match.is_function())
        assert.spy(_G.ngx.thread.wait).was.called_with(thread)
        assert.spy(logger.error).was.called_with('failed to run Collector<test>:periodically(): ', 'test error')
        assert.spy(logger.error).was.called(1)
        assert.spy(_G.ngx.timer.at).was.called(1)
    end)

    it('handler with collectors', function()
        local test_collector = mock({name='test', periodically=function() end})
        local thread = {[[thread stub]]}

        stub.new(_G.ngx.thread, 'spawn').on_call_with(match.is_function()).returns(thread)
        stub.new(_G.ngx.thread, 'wait').on_call_with(thread).returns(true, nil)
        stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), {test_collector}).returns(true, nil)

        scheduler.__private__.handler(false, {test_collector})

        assert.spy(_G.ngx.thread.spawn).was.called_with(match.is_function())
        assert.spy(_G.ngx.thread.wait).was.called_with(thread)
        assert.spy(_G.ngx.timer.at).was.called_with(1, match.is_function(), {test_collector})
        assert.spy(_G.ngx.timer.at).was.called(1)
        assert.spy(logger.error).was_not.called()
    end)
end)
