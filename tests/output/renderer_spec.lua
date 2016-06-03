require('tests.bootstrap')(assert)

describe('output.helper', function()

  local match = require 'luassert.match'
  local helper
  local renderer
  local namespaces

  setup(function()
    helper = mock(require 'nginx-metrix.output.helper')
    namespaces = mock(require 'nginx-metrix.storage.namespaces', true)
  end)

  before_each(function()
    renderer = require 'nginx-metrix.output.renderer'
  end)

  after_each(function()
    mock.clear(helper)
    mock.clear(namespaces)
    namespaces.list:revert()
    stub(namespaces, 'list')
    package.loaded['nginx-metrix.output.renderer'] = nil
    package.loaded['nginx-metrix.collectors'] = nil
    _G.ngx = nil
  end)

  teardown(function()
    package.loaded['nginx-metrix.output.helper'] = nil
  end)

  it('filter_vhosts', function()
    local test_vhosts = { 'first.com', 'second.com', 'www2.second.com', 'third.com' }

    local actual_vhosts

    -- filter by string
    actual_vhosts = renderer.__private__.filter_vhosts(test_vhosts, 'second.com'):totable()
    assert.is_same({ 'second.com', 'www2.second.com' }, actual_vhosts)

    -- filter by pattern
    actual_vhosts = renderer.__private__.filter_vhosts(test_vhosts, '^%w-s%w-[.]com$'):totable()
    assert.is_same({ 'first.com', 'second.com' }, actual_vhosts)

    -- filter by list of strings
    actual_vhosts = renderer.__private__.filter_vhosts(test_vhosts, { 'second.com', 'third.com' }):totable()
    assert.is_same({ 'second.com', 'third.com' }, actual_vhosts)

    -- filter by function
    actual_vhosts = renderer.__private__.filter_vhosts(test_vhosts, function(vhost) return vhost:match('^s') end):totable()
    assert.is_same({ 'second.com' }, actual_vhosts)

    -- inavlid filter
    actual_vhosts = renderer.__private__.filter_vhosts(test_vhosts, 13):totable()
    assert.is_same(test_vhosts, actual_vhosts)
  end)

  it('get_vhosts_json', function()
    local actual = renderer.__private__.get_vhosts_json(iter({ 'first.com', 'second.com' }))
    assert.json_equal('["first.com","second.com"]', actual)
  end)

  it('get_vhosts_text', function()
    local actual = renderer.__private__.get_vhosts_text(iter({ 'first.com', 'second.com' }))
    assert.is_equal("vhosts:\n	- first.com\n	- second.com", actual)
  end)

  it('get_vhosts_html', function()
    local actual = renderer.__private__.get_vhosts_html(iter({ 'first.com', 'second.com' }))
    assert.matches('<ul class="list[-]group"><li class="list[-]group[-]item">first[.]com</li><li class="list[-]group[-]item">second[.]com</li></ul>', actual)
  end)

  it('render_vhosts', function()
    local vhosts = iter({ 'first.com', 'second.com' })

    local s
    local actual

    s = stub.new(helper, 'get_format').on_call_with().returns('json')
    actual = renderer.__private__.render_vhosts(vhosts)
    assert.json_equal('["first.com","second.com"]', actual)
    s:revert()

    s = stub.new(helper, 'get_format').on_call_with().returns('text')
    actual = renderer.__private__.render_vhosts(vhosts)
    assert.is_equal("vhosts:\n	- first.com\n	- second.com", actual)
    s:revert()

    s = stub.new(helper, 'get_format').on_call_with().returns('html')
    actual = renderer.__private__.render_vhosts(vhosts)
    assert.matches('<ul class="list[-]group"><li class="list[-]group[-]item">first[.]com</li><li class="list[-]group[-]item">second[.]com</li></ul>', actual)
    s:revert()
  end)

  it('get_stats_json with multiple vhosts', function()
    local v = 0
    local test_collector = mock({ name = 'test', get_raw_stats = function() v = v + 1; return iter({ test = v }) end })
    local collectors = require 'nginx-metrix.collectors'
    collectors.all = iter({ test_collector })

    local actual = renderer.__private__.get_stats_json(iter({ 'first.com', 'second.com' }))

    assert.spy(namespaces.activate).was.called(2)
    assert.spy(namespaces.reset_active).was.called(2)
    assert.spy(test_collector.get_raw_stats).was.called(2)

    assert.json_equal('{"first.com":{"vhost":"first.com","test":{"test":1}},"service":"nginx-metrix","second.com":{"vhost":"second.com","test":{"test":2}}}', actual)
  end)

  it('get_stats_json with single vhosts', function()
    local v = 0
    local test_collector = mock({ name = 'test', get_raw_stats = function() v = v + 1; return iter({ test = v }) end })
    local collectors = require 'nginx-metrix.collectors'
    collectors.all = iter({ test_collector })

    local actual = renderer.__private__.get_stats_json(iter({ 'first.com' }))

    assert.spy(namespaces.activate).was.called(1)
    assert.spy(namespaces.reset_active).was.called(1)
    assert.spy(test_collector.get_raw_stats).was.called(1)

    assert.json_equal('{"service":"nginx-metrix","vhost":"first.com","test":{"test":1}}', actual)
  end)

  it('get_stats_text', function()
    local v = 0
    local test_collector = mock({ name = 'test', get_text_stats = function() v = v + 1; return "test=" .. v .. "\n" end })
    local collectors = require 'nginx-metrix.collectors'
    collectors.all = iter({ test_collector })

    local actual = renderer.__private__.get_stats_text(iter({ 'first.com', 'second.com' }))

    assert.spy(namespaces.activate).was.called(2)
    assert.spy(namespaces.reset_active).was.called(2)
    assert.spy(test_collector.get_text_stats).was.called(2)

    assert.matches('### Nginx Metrix v.- ###', actual)
    assert.matches('%[first[.]com@test%]', actual)
    assert.matches('test=1', actual)
    assert.matches('%[second[.]com@test%]', actual)
    assert.matches('test=2', actual)
  end)

  it('get_stats_html', function()
    local v = 0
    local test_collector = mock({ name = 'test', get_html_stats = function() v = v + 1; return "<th>test</th><td>" .. v .. "</td>" end })
    local collectors = require 'nginx-metrix.collectors'
    collectors.all = iter({ test_collector })

    local actual = renderer.__private__.get_stats_html(iter({ 'first.com', 'second.com' }))

    assert.spy(namespaces.activate).was.called(2)
    assert.spy(namespaces.reset_active).was.called(2)
    assert.spy(test_collector.get_html_stats).was.called(2)

    assert.matches('<title>Nginx Metrix</title>', actual)
    assert.matches('<h3 class="panel[-]title">first[.]com</h3>', actual)
    assert.matches('<th>test</th><td>1</td>', actual)
    assert.matches('<h3 class="panel[-]title">second[.]com</h3>', actual)
    assert.matches('<th>test</th><td>2</td>', actual)
  end)

  it('render_stats', function()
    local vhosts = iter({ 'first.com', 'second.com' })
    local v = 0
    local test_collector = mock({
      name = 'test',
      get_raw_stats = function() v = v + 1; return iter({ test = v }) end,
      get_text_stats = function() v = v + 1; return "test=" .. v .. "\n" end,
      get_html_stats = function() v = v + 1; return "<th>test</th><td>" .. v .. "</td>" end,
    })
    local collectors = require 'nginx-metrix.collectors'
    collectors.all = iter({ test_collector })

    local s
    local actual

    s = stub.new(helper, 'get_format').on_call_with().returns('json')
    actual = renderer.__private__.render_stats(vhosts)
    assert.json_equal('{"first.com":{"vhost":"first.com","test":{"test":1}},"service":"nginx-metrix","second.com":{"vhost":"second.com","test":{"test":2}}}', actual)
    s:revert()

    s = stub.new(helper, 'get_format').on_call_with().returns('text')
    actual = renderer.__private__.render_stats(vhosts)
    assert.matches('### Nginx Metrix v.- ###', actual)
    assert.matches('%[first[.]com@test%]', actual)
    assert.matches('test=3', actual)
    assert.matches('%[second[.]com@test%]', actual)
    assert.matches('test=4', actual)
    s:revert()

    s = stub.new(helper, 'get_format').on_call_with().returns('html')
    actual = renderer.__private__.render_stats(vhosts)
    assert.matches('<title>Nginx Metrix</title>', actual)
    assert.matches('<h3 class="panel[-]title">first[.]com</h3>', actual)
    assert.matches('<th>test</th><td>5</td>', actual)
    assert.matches('<h3 class="panel[-]title">second[.]com</h3>', actual)
    assert.matches('<th>test</th><td>6</td>', actual)
    s:revert()
  end)

  it('render (stats) without vhost arg', function()
    namespaces.list.on_call_with().returns({ 'one-first.com', 'one-first-com', 'second.com' })

    local v = 0
    local test_collector = mock({ name = 'test', get_raw_stats = function() v = v + 1; return iter({ test = v }) end })
    local collectors = require 'nginx-metrix.collectors'
    collectors.all = iter({ test_collector })

    _G.ngx = mock({
      say = function() end,
      req = {
        get_uri_args = function() return {} end,
      }
    })


    local s1 = stub.new(helper, 'get_format').on_call_with().returns('json')
    local s2 = stub.new(helper, 'set_content_type_header')
    renderer.render({ vhosts_filter = '.*' })
    assert.spy(_G.ngx.say).was.called_with(match.json_equal('{"second.com":{"test":{"test":3},"vhost":"second.com"},"one-first.com":{"test":{"test":1},"vhost":"one-first.com"},"one-first-com":{"test":{"test":2},"vhost":"one-first-com"},"service":"nginx-metrix"}'))
    assert.spy(_G.ngx.say).was.called(1)
    s1:revert()
    s2:revert()
  end)

  it('render (stats) with vhost arg', function()
    namespaces.list.on_call_with().returns({ 'one-first.com', 'one-first-com', 'second.com' })

    local v = 0
    local test_collector = mock({ name = 'test', get_raw_stats = function() v = v + 1; return iter({ test = v }) end })
    local collectors = require 'nginx-metrix.collectors'
    collectors.all = iter({ test_collector })

    _G.ngx = mock({
      say = function() end,
      req = {
        get_uri_args = function() return { vhost = 'one-first.com' } end,
      }
    })

    local s1 = stub.new(helper, 'get_format').on_call_with().returns('json')
    local s2 = stub.new(helper, 'set_content_type_header')
    renderer.render({ vhosts_filter = '.*' })
    assert.spy(_G.ngx.say).was.called(1)
    assert.spy(_G.ngx.say).was.called_with(match.json_equal('{"vhost":"one-first.com","test":{"test":1},"service":"nginx-metrix"}'))
    s1:revert()
    s2:revert()
  end)

  it('render (vhosts)', function()
    namespaces.list.on_call_with().returns({ 'first.com', 'second.com', 'third.com', 'fourth.org' })

    local v = 0
    local test_collector = mock({ name = 'test', get_raw_stats = function() v = v + 1; return iter({ test = v }) end })
    local collectors = require 'nginx-metrix.collectors'
    collectors.all = iter({ test_collector })

    _G.ngx = mock({
      say = function() end,
      req = {
        get_uri_args = function() return { list_vhosts = 1, vhost = 'first.com' } end,
      }
    })

    local s1 = stub.new(helper, 'get_format').on_call_with().returns('json')
    local s2 = stub.new(helper, 'set_content_type_header')
    renderer.render({ vhosts_filter = { 'second.com', 'third.com', 'fourth.org' } })
    assert.spy(_G.ngx.say).was.called(1)
    assert.spy(_G.ngx.say).was.called_with(match.json_equal({ 'second.com', 'third.com', 'fourth.org' }))
    s1:revert()
    s2:revert()
  end)
end)
