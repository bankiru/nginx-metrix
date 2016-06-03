require('tests.bootstrap')(assert)

describe('scheduler', function()
  local scheduler
  local dict_mock
  local logger
  local match

  setup(function()
    logger = mock(require 'nginx-metrix.logger', true)
    match = require 'luassert.match'

    dict_mock = require 'nginx-metrix.storage.dict'

    _G.ngx = {
      timer = {
        at = function() end,
      },
      thread = {
        spawn = function() end,
        wait = function() end,
      },
      now = function() return os.time() end,
    }
  end)

  teardown(function()
    mock.revert(dict_mock)
    package.loaded['nginx-metrix.storage.dict'] = nil
    package.loaded['nginx-metrix.logger'] = nil
    _G.ngx = nil
  end)

  before_each(function()
    mock(_G.ngx)

    mock(dict_mock, true)
    package.loaded['nginx-metrix.storage.dict'] = dict_mock

    scheduler = require 'nginx-metrix.scheduler'
  end)

  after_each(function()
    package.loaded['nginx-metrix.scheduler'] = nil
    mock.clear(logger)
    mock.revert(dict_mock)
    mock.revert(_G.ngx)
  end)


  it('get lock ok', function()
    local test_lock_id = 'test_lock_id'
    stub.new(_G.ngx, 'now').on_call_with().returns(test_lock_id)

    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, scheduler.__private__.lock_timeout()).returns(true, nil, false)
    local lock_success, lock_id = scheduler.__private__.get_lock()
    assert.spy(dict_mock.add).was.called(1)
    assert.spy(dict_mock.add).was.called_with(scheduler.__private__.lock_key(), match._, scheduler.__private__.lock_timeout())
    assert.is_true(lock_success)
    assert.is_equal(test_lock_id, lock_id)
  end)

  it('get lock failed on existent lock', function()
    local test_lock_id = 'test_lock_id'
    stub.new(_G.ngx, 'now').on_call_with().returns(test_lock_id)

    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, scheduler.__private__.lock_timeout()).returns(false, 'exists', false)
    local lock_success, lock_id = scheduler.__private__.get_lock()
    assert.spy(dict_mock.add).was.called(1)
    assert.spy(dict_mock.add).was.called_with(scheduler.__private__.lock_key(), match._, scheduler.__private__.lock_timeout())
    assert.is_false(lock_success)
    assert.is_nil(lock_id)
  end)

  it('get lock ok on stale lock', function()
    local test_lock_id = 'test_lock_id'
    stub.new(_G.ngx, 'now').on_call_with().returns(test_lock_id)

    scheduler.__private__.lock_timeout(0.1)

    local lock_success, lock_id

    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, match._).returns(true, nil, false)
    lock_success, lock_id = scheduler.__private__.get_lock()
    assert.is_true(lock_success)
    assert.is_equal(test_lock_id, lock_id)
    assert.spy(dict_mock.add).was.called_with(scheduler.__private__.lock_key(), match._, scheduler.__private__.lock_timeout())

    test_lock_id = 'yet-another-test-lock-id'
    stub.new(_G.ngx, 'now').on_call_with().returns(test_lock_id)

    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, match._).returns(true, nil, true)
    lock_success, lock_id = scheduler.__private__.get_lock()
    assert.is_true(lock_success)
    assert.is_equal(test_lock_id, lock_id)
    assert.spy(dict_mock.add).was.called_with(scheduler.__private__.lock_key(), match._, scheduler.__private__.lock_timeout())

    assert.spy(dict_mock.add).was.called(2)
  end)

  it('drop lock ok on own lock', function()
    local test_lock_id = 'test_lock_id'

    dict_mock.get.on_call_with(scheduler.__private__.lock_key()).returns(test_lock_id, 0)

    assert.is_true(scheduler.__private__.drop_lock(test_lock_id))

    assert.spy(dict_mock.get).was.called_with(scheduler.__private__.lock_key())
    assert.spy(dict_mock.get).was.called(1)
    assert.spy(dict_mock.delete).was.called_with(scheduler.__private__.lock_key())
    assert.spy(dict_mock.delete).was.called(1)
  end)

  it('drop lock failed on non own lock', function()
    dict_mock.get.on_call_with(scheduler.__private__.lock_key()).returns(123.456, 0)

    assert.is_false(scheduler.__private__.drop_lock(456.123))

    assert.spy(dict_mock.get).was.called_with(scheduler.__private__.lock_key())
    assert.spy(dict_mock.get).was.called(1)
    assert.spy(dict_mock.delete).was_not.called()
  end)


  it('attach_collector', function()
    scheduler.attach_collector({})
    assert.is_equal(0, length(scheduler.__private__.get_collectors()))

    scheduler.attach_collector({ name = 'test', aggregate = function() end })
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
    local test_collector = { name = 'test', aggregate = function() end }
    scheduler.attach_collector(test_collector)

    stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), { test_collector }).returns(true, nil)

    assert.is_true(scheduler.start())
    assert.spy(_G.ngx.timer.at).was.called_with(1, match.is_function(), { test_collector })
    assert.spy(_G.ngx.timer.at).was.called(1)
    assert.spy(logger.error).was_not.called()
  end)

  it('handler on premature call', function()
    local test_collector = mock({ name = 'test', aggregate = function() end })
    scheduler.__private__.handler(true, { test_collector })
    assert.spy(_G.ngx.thread.spawn).was_not.called()
    assert.spy(_G.ngx.thread.wait).was_not.called()
    assert.spy(_G.ngx.timer.at).was_not.called()
    assert.spy(logger.error).was_not.called()
  end)

  it('handler failed to start next iter', function()
    local test_collector = mock({ name = 'test', aggregate = function() end })

    local test_lock_id = 'test_lock_id'
    stub.new(_G.ngx, 'now').on_call_with().returns(test_lock_id)
    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, match._).returns(true, nil, false)
    dict_mock.get.on_call_with(scheduler.__private__.lock_key()).returns(test_lock_id, 0)

    local thread = { [[thread stub]] }
    stub.new(_G.ngx.thread, 'spawn').on_call_with(match.is_function()).returns(thread)
    stub.new(_G.ngx.thread, 'wait').on_call_with(thread).returns(true, nil)

    stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), {test_collector}).returns(false, 'test error')

    scheduler.__private__.handler(false, {test_collector})

    assert.spy(_G.ngx.thread.spawn).was.called(1)
    assert.spy(_G.ngx.thread.wait).was.called(1)
    assert.spy(_G.ngx.timer.at).was.called(1)

    assert.spy(dict_mock.add).was.called_with(scheduler.__private__.lock_key(), test_lock_id, scheduler.__private__.lock_timeout())
    assert.spy(dict_mock.add).was.called(1)
    assert.spy(dict_mock.delete).was.called_with(scheduler.__private__.lock_key())
    assert.spy(dict_mock.delete).was.called(1)

    assert.spy(logger.error).was.called_with('Failed to continue the scheduler - failed to create the timer: ', 'test error')
    assert.spy(logger.error).was.called(1)
  end)

  it('handler without collectors', function()
    local test_lock_id = 'test_lock_id'

    stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), {}).returns(true, nil)

    scheduler.__private__.handler(false, {})

    assert.spy(_G.ngx.thread.spawn).was_not.called()
    assert.spy(_G.ngx.thread.wait).was_not.called()
    assert.spy(_G.ngx.timer.at).was.called_with(1, match.is_function(), {})
    assert.spy(_G.ngx.timer.at).was.called(1)
    assert.spy(logger.error).was_not.called()
    assert.spy(dict_mock.add).was_not.called()
    assert.spy(dict_mock.get).was_not.called()
    assert.spy(dict_mock.delete).was_not.called()
  end)

  it('handler log error if can not wait thread', function()
    local test_collector = mock({ name = 'test', aggregate = function() end })

    local test_lock_id = 'test_lock_id'
    stub.new(_G.ngx, 'now').on_call_with().returns(test_lock_id)
    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, match._).returns(true, nil, false)
    dict_mock.get.on_call_with(scheduler.__private__.lock_key()).returns(test_lock_id, 0)

    local thread = { [[thread stub]] }

    stub.new(_G.ngx.thread, 'spawn').on_call_with(match.is_function()).returns(thread)
    stub.new(_G.ngx.thread, 'wait').on_call_with(thread).returns(false, 'test error')
    stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), { test_collector }).returns(true, nil)

    scheduler.__private__.handler(false, { test_collector })

    assert.spy(_G.ngx.thread.spawn).was.called_with(match.is_function())
    assert.spy(_G.ngx.thread.wait).was.called_with(thread)
    assert.spy(logger.error).was.called_with('failed to run Collector<test>:aggregate(): ', 'test error')
    assert.spy(logger.error).was.called(1)
    assert.spy(_G.ngx.timer.at).was.called(1)
    assert.spy(dict_mock.add).was.called_with(scheduler.__private__.lock_key(), test_lock_id, scheduler.__private__.lock_timeout())
    assert.spy(dict_mock.add).was.called(1)
    assert.spy(dict_mock.delete).was.called_with(scheduler.__private__.lock_key())
    assert.spy(dict_mock.delete).was.called(1)
  end)

  it('handler with collectors', function()
    local test_collector = mock({ name = 'test', aggregate = function() end })

    local test_lock_id = 'test_lock_id'
    stub.new(_G.ngx, 'now').on_call_with().returns(test_lock_id)
    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, match._).returns(true, nil, false)
    dict_mock.get.on_call_with(scheduler.__private__.lock_key()).returns(test_lock_id, 0)

    local thread = { [[thread stub]] }

    stub.new(_G.ngx.thread, 'spawn').on_call_with(match.is_function()).returns(thread)
    stub.new(_G.ngx.thread, 'wait').on_call_with(thread).returns(true, nil)
    stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), { test_collector }).returns(true, nil)
    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, match._).returns(true, nil, false)

    scheduler.__private__.handler(false, { test_collector })

    assert.spy(_G.ngx.thread.spawn).was.called_with(match.is_function())
    assert.spy(_G.ngx.thread.wait).was.called_with(thread)
    assert.spy(_G.ngx.timer.at).was.called_with(1, match.is_function(), { test_collector })
    assert.spy(_G.ngx.timer.at).was.called(1)
    assert.spy(logger.error).was_not.called()
    assert.spy(dict_mock.add).was.called_with(scheduler.__private__.lock_key(), test_lock_id, scheduler.__private__.lock_timeout())
    assert.spy(dict_mock.add).was.called(1)
    assert.spy(dict_mock.delete).was.called_with(scheduler.__private__.lock_key())
    assert.spy(dict_mock.delete).was.called(1)
  end)

  it('only one handler per time', function()
    local test_collector = mock({ name = 'test', aggregate = function() end })

    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, match._).returns(false, 'exists', false)

    stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), { test_collector }).returns(true, nil)

    scheduler.__private__.handler(false, { test_collector })
    assert.spy(_G.ngx.thread.spawn).was_not.called()
    assert.spy(_G.ngx.thread.wait).was_not.called()
    assert.spy(_G.ngx.timer.at).was.called_with(1, match.is_function(), { test_collector })
    assert.spy(_G.ngx.timer.at).was.called(1)
    assert.spy(logger.error).was_not.called()
    assert.spy(dict_mock.get).was_not.called(1)
    assert.spy(dict_mock.delete).was_not.called(1)
  end)
end)
