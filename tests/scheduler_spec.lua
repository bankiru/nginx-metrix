require('tests.bootstrap')(assert)

describe('scheduler', function()
  local scheduler
  local dict_mock
  local namespaces
  local logger
  local match

  setup(function()
    logger = mock(require 'nginx-metrix.logger', true)
    match = require 'luassert.match'

    dict_mock = require 'nginx-metrix.storage.dict'
    namespaces = require 'nginx-metrix.storage.namespaces'

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
    mock.revert(namespaces)
    package.loaded['nginx-metrix.storage.namespaces'] = nil
    package.loaded['nginx-metrix.storage.dict'] = nil
    package.loaded['nginx-metrix.logger'] = nil
    _G.ngx = nil
  end)

  before_each(function()
    mock(_G.ngx)

    mock(dict_mock, true)
    mock(namespaces, true)
    package.loaded['nginx-metrix.storage.dict'] = dict_mock

    scheduler = require 'nginx-metrix.scheduler'
  end)

  after_each(function()
    package.loaded['nginx-metrix.scheduler'] = nil
    mock.clear(logger)
    mock.revert(dict_mock)
    mock.revert(_G.ngx)
  end)

  it('setup lock ok', function()
    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, scheduler.__private__.lock_timeout()).returns(true, nil, false)
    local lock_success = scheduler.__private__.setup_lock()
    assert.spy(dict_mock.add).was.called(1)
    assert.spy(dict_mock.add).was.called_with(scheduler.__private__.lock_key(), match._, scheduler.__private__.lock_timeout())
    assert.is_true(lock_success)
  end)

  it('setup lock failed on existent lock', function()
    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, scheduler.__private__.lock_timeout()).returns(false, 'exists', false)
    local lock_success = scheduler.__private__.setup_lock()
    assert.spy(dict_mock.add).was.called(1)
    assert.spy(dict_mock.add).was.called_with(scheduler.__private__.lock_key(), match._, scheduler.__private__.lock_timeout())
    assert.is_false(lock_success)
  end)

  it('setup lock ok on stale lock', function()
    scheduler.__private__.lock_timeout(0.1)

    local lock_success

    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, match._).returns(true, nil, false)
    lock_success = scheduler.__private__.setup_lock()
    assert.is_true(lock_success)
    assert.spy(dict_mock.add).was.called_with(scheduler.__private__.lock_key(), match._, scheduler.__private__.lock_timeout())

    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, match._).returns(true, nil, true)
    lock_success = scheduler.__private__.setup_lock()
    assert.is_true(lock_success)
    assert.spy(dict_mock.add).was.called_with(scheduler.__private__.lock_key(), match._, scheduler.__private__.lock_timeout())

    assert.spy(dict_mock.add).was.called(2)
  end)

  it('attach_collector', function()
    scheduler.attach_collector({})
    assert.is_equal(0, length(scheduler.__private__.collectors()))

    scheduler.attach_collector({ name = 'test', aggregate = function() end })
    assert.is_equal(1, length(scheduler.__private__.collectors()))
  end)

  it('start failed because worker_id', function()
    local worker_id = 13
    dict_mock.safe_incr.on_call_with('worker_id').returns(nil, 'test error')

    assert.is_false(scheduler.start())
    assert.spy(_G.ngx.timer.at).was_not.called()
    assert.spy(logger.error).was.called_with('Can not make worker_id', 'test error')
    assert.spy(logger.error).was.called(1)
  end)

  it('start failed because timer', function()
    local worker_id = 13
    dict_mock.safe_incr.on_call_with('worker_id').returns(worker_id, nil)
    stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), {}, worker_id).returns(false, 'test error')

    assert.is_false(scheduler.start())
    assert.spy(_G.ngx.timer.at).was.called_with(1, match.is_function(), {}, worker_id)
    assert.spy(_G.ngx.timer.at).was.called(1)
    assert.spy(logger.error).was.called_with('[scheduler #' .. worker_id .. '] Failed to start the scheduler - failed to create the timer', 'test error')
    assert.spy(logger.error).was.called(1)
  end)

  it('start without collectors', function()
    local worker_id = 13
    dict_mock.safe_incr.on_call_with('worker_id').returns(worker_id, nil)
    stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), {}, worker_id).returns(true, nil)

    assert.is_true(scheduler.start())
    assert.spy(_G.ngx.timer.at).was.called(1)
    assert.spy(logger.error).was_not.called()
  end)

  it('start with collectors', function()
    local test_collector = { name = 'test', aggregate = function() end }
    scheduler.attach_collector(test_collector)

    local worker_id = 13
    dict_mock.safe_incr.on_call_with('worker_id').returns(worker_id, nil)
    stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), { test_collector }, worker_id).returns(true, nil)

    assert.is_true(scheduler.start())
    assert.spy(_G.ngx.timer.at).was.called_with(1, match.is_function(), { test_collector }, worker_id)
    assert.spy(_G.ngx.timer.at).was.called(1)
    assert.spy(logger.error).was_not.called()
  end)

  it('handler on premature call', function()
    local process_stub = mock({process = function() end}).process
    scheduler.__private__._process(process_stub)

    scheduler.__private__.handler(true, {}, 1)
    assert.spy(process_stub).was_not.called()
    assert.spy(_G.ngx.timer.at).was_not.called()
    assert.spy(logger.error).was_not.called()
  end)

  it('handler failed to start next iter', function()
    local worker_id = 13

    local process_stub = mock({process = function() end}).process
    scheduler.__private__._process(process_stub)

    namespaces.list.on_call_with().returns({})
    stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), {}, worker_id).returns(false, 'test error')

    scheduler.__private__.handler(false, {}, worker_id)

    assert.spy(process_stub).was.called_with({}, {}, worker_id)
    assert.spy(process_stub).was.called(1)

    assert.spy(logger.error).was.called_with('[scheduler #' .. worker_id .. '] Failed to continue the scheduler - failed to create the timer', 'test error')
    assert.spy(logger.error).was.called(1)
  end)

  it('process without collectors', function()
    local worker_id = 13

    scheduler.__private__.process({}, {}, worker_id)

    assert.spy(dict_mock.add).was_not.called()
    assert.spy(logger.error).was_not.called()
    assert.spy(logger.debug).was.called_with('[scheduler #' .. worker_id .. '] collectors list is empty, skipping')
  end)

  it('process without namespaces', function()
    local worker_id = 13

    scheduler.__private__.process({[[collector]]}, {}, worker_id)

    assert.spy(dict_mock.add).was_not.called()
    assert.spy(logger.error).was_not.called()
    assert.spy(logger.debug).was.called_with('[scheduler #' .. worker_id .. '] namespaces list is empty, skipping')
  end)

  it('process skips if can not setup lock', function()
    local worker_id = 13

    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), scheduler.__private__.lock_key(), scheduler.__private__.lock_timeout()).returns(false, 'exists', false)

    scheduler.__private__.process({[[collector]]}, {'example.com'}, worker_id)

    assert.spy(dict_mock.add).was.called_with(scheduler.__private__.lock_key(), scheduler.__private__.lock_key(), scheduler.__private__.lock_timeout())
    assert.spy(dict_mock.add).was.called(1)
    assert.spy(logger.error).was_not.called()
    assert.spy(logger.debug).was.called_with('[scheduler #' .. worker_id .. '] lock still exists, skipping')
  end)

  it('process logs error if can not wait thread', function()
    local test_collector = mock({ name = 'test', aggregate = function() end })

    local worker_id = 13

    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, match._).returns(true, nil, false)

    local thread = { [[thread stub]] }

    stub.new(_G.ngx.thread, 'spawn').on_call_with(match.is_function()).returns(thread)
    stub.new(_G.ngx.thread, 'wait').on_call_with(thread).returns(false, 'test error')
    stub.new(_G.ngx.timer, 'at').on_call_with(1, match.is_function(), { test_collector }, {'example.com'} , worker_id).returns(true, nil)

--    logger.error.on_call_with(match._, match._).invokes(function(...) print(require 'inspect'({...})) end)

    scheduler.__private__.process({ test_collector }, {'example.com'}, worker_id)

    assert.spy(dict_mock.add).was.called_with(scheduler.__private__.lock_key(), scheduler.__private__.lock_key(), scheduler.__private__.lock_timeout())
    assert.spy(dict_mock.add).was.called(1)

    assert.spy(_G.ngx.thread.spawn).was.called_with(match.is_function())
    assert.spy(_G.ngx.thread.wait).was.called_with(thread)

    assert.spy(logger.error).was.called_with("[scheduler #" .. worker_id .. "] failed to run Collector<test>:aggregate() on namespace 'example.com'", 'test error')
    assert.spy(logger.error).was.called(1)
  end)

  it('process with collectors', function()
    local test_collector = mock({ name = 'test', aggregate = function() end })

    local worker_id = 13

    dict_mock.add.on_call_with(scheduler.__private__.lock_key(), match._, match._).returns(true, nil, false)

    local thread = { func = nil }

    stub.new(_G.ngx.thread, 'spawn').on_call_with(match.is_function()).invokes(function(func) thread.func = func; return thread end)
    stub.new(_G.ngx.thread, 'wait').on_call_with(match._).invokes(function(thread) thread.func(); return true, nil end)

    logger.error.on_call_with(match._, match._).invokes(function(...) print(require 'inspect'({...})) end)

    scheduler.__private__.process({ test_collector }, {'first.com', 'second.org'}, worker_id)

    assert.spy(dict_mock.add).was.called_with(scheduler.__private__.lock_key(), scheduler.__private__.lock_key(), scheduler.__private__.lock_timeout())
    assert.spy(dict_mock.add).was.called(1)

    assert.spy(_G.ngx.thread.spawn).was.called_with(match.is_function())
    assert.spy(_G.ngx.thread.wait).was.called_with(thread)
    assert.spy(test_collector.aggregate).was.called(2)

    assert.spy(namespaces.list).was.called(1)
    assert.spy(namespaces.activate).was.called_with('first.com')
    assert.spy(namespaces.activate).was.called_with('second.org')
    assert.spy(namespaces.activate).was.called(2)

    assert.spy(logger.error).was_not.called()
  end)
end)
