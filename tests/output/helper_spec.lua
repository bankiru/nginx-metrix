require('tests.bootstrap')(assert)

describe('output.helper', function()

  local logger
  local helper

  setup(function()
    logger = mock(require 'nginx-metrix.logger', true)
  end)

  before_each(function()
    helper = require 'nginx-metrix.output.helper'
  end)

  after_each(function()
    mock.clear(logger)
    package.loaded['nginx-metrix.output.helper'] = nil
    _G.ngx = nil
  end)

  teardown(function()
    package.loaded['nginx-metrix.logger'] = nil
  end)

  it('header_http_accept', function()
    _G.ngx = {
      req = {
        get_headers = function()
          return {
            accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
          }
        end
      }
    }

    local iterator = helper.__private__.header_http_accept()
    assert.is_table(iterator)
    assert.is_function(iterator.totable)
    assert.is_same({ "text/html", "application/xhtml", "application/xml", "image/webp" }, iterator:totable())
  end)

  it('format_value', function()
    local value1 = helper.__private__.format_value({}, 'test', 13.3)
    assert.is_equal(13.3, value1)

    local test_collector = { fields = { test = { format = '%d' } } }
    local value2 = helper.__private__.format_value(test_collector, 'test', 13.3)
    assert.is_equal('13', value2)
  end)

  it('get_format by uri_args', function()
    _G.ngx = mock({
      req = {
        get_headers = function() return {} end,
        get_uri_args = function() return {} end,
      }
    })

    stub.new(_G.ngx.req, 'get_uri_args').on_call_with().returns({ format = 'json' })
    local format = helper.get_format()
    assert.spy(_G.ngx.req.get_uri_args).was.called(1)
    assert.spy(_G.ngx.req.get_headers).was_not.called()
    assert.is_equal('json', format)
  end)

  it('get_format by accept header', function()
    _G.ngx = mock({
      req = {
        get_headers = function() return {} end,
        get_uri_args = function() return {} end,
      }
    })

    stub.new(_G.ngx.req, 'get_headers').on_call_with().returns({ accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' })
    local format = helper.get_format()
    assert.spy(_G.ngx.req.get_uri_args).was.called(1)
    assert.spy(_G.ngx.req.get_headers).was.called(1)
    assert.is_equal('html', format)
  end)

  it('get_format fallback to default without specified format', function()
    _G.ngx = mock({
      req = {
        get_headers = function() return {} end,
        get_uri_args = function() return {} end,
      }
    })

    local format = helper.get_format()
    assert.spy(_G.ngx.req.get_uri_args).was.called(1)
    assert.spy(_G.ngx.req.get_headers).was.called(1)
    assert.is_equal('text', format)
  end)

  it('get_format fallback to default with wrong format', function()
    _G.ngx = mock({
      req = {
        get_headers = function() return {} end,
        get_uri_args = function() return {} end,
      }
    })

    stub.new(_G.ngx.req, 'get_uri_args').on_call_with().returns({ format = 'invalid' })
    local format = helper.get_format()
    assert.spy(_G.ngx.req.get_uri_args).was.called(1)
    assert.spy(_G.ngx.req.get_headers).was.called(1)
    assert.is_equal('text', format)
  end)

  it('set_content_type_header do not set content type when headers already sent', function()
    _G.ngx = mock({
      header = {},
      headers_sent = true,
      req = {
        get_uri_args = function() return { format = 'json' } end,
      }
    })

    helper.set_content_type_header()

    assert.spy(logger.warn).was.called(1)
    assert.spy(logger.warn).was.called_with('Can not set Content-type header because headers already sent')
    assert.spy(_G.ngx.req.get_uri_args).was_not.called()
  end)

  it('set_content_type_header success', function()
    _G.ngx = mock({
      header = {},
      headers_sent = false,
      req = {
        get_uri_args = function() return { format = 'json' } end,
      }
    })

    helper.set_content_type_header()
    assert.is_equal('application/json', ngx.header.content_type)

    helper.set_content_type_header('text/plain')
    assert.is_equal('text/plain', ngx.header.content_type)

    assert.spy(_G.ngx.req.get_uri_args).was.called(1)
    assert.spy(logger.warn).was_not.called()
  end)

  it('title', function()
    assert.is_function(helper.title)
    assert.is_equal('Nginx Metrix', helper.title())
  end)

  it('title_version', function()
    assert.is_function(helper.title_version)
    assert.matches('^Nginx Metrix v.+$', helper.title_version())
  end)

  it('html.page_template', function()
    assert.is_function(helper.html.page_template)
    assert.is_table(helper.html.page_template())
    assert.is_function(helper.html.page_template().gen)
  end)

  it('html.section_template', function()
    assert.is_function(helper.html.section_template)
    assert.is_table(helper.html.section_template())
    assert.is_function(helper.html.section_template().gen)
  end)

  it('html.table_template', function()
    assert.is_function(helper.html.table_template)
    assert.is_table(helper.html.table_template())
    assert.is_function(helper.html.section_template().gen)
  end)

  it('html.render_stats', function()
    local test_collector = mock({
      fields = { test = { format = '%d' } },
      get_raw_stats = function() return iter({ test = 7 }) end
    })

    local stats = helper.html.render_stats(test_collector)
    assert.spy(test_collector.get_raw_stats).was.called(1)
    assert.spy(test_collector.get_raw_stats).was.called_with(test_collector)
    assert.matches('<tr><th class="col[-]md[-]2">test</th><td>7</td></tr>', stats)
  end)

  it('text.header', function()
    assert.is_function(helper.text.header)
    local expected = "### " .. helper.title_version() .. " ###\n"
    assert.is_equal(expected, helper.text.header())
  end)

  it('text.section_template', function()
    assert.is_function(helper.text.section_template)
    assert.is_table(helper.text.section_template())
    assert.is_function(helper.text.section_template().gen)
  end)

  it('text.item_template', function()
    assert.is_function(helper.text.item_template)
    assert.is_table(helper.text.item_template())
    assert.is_function(helper.text.item_template().gen)
  end)

  it('text.render_stats', function()
    local test_collector = mock({
      fields = { test = { format = '%d' } },
      get_raw_stats = function() return iter({ test = 7 }) end
    })

    local stats = helper.text.render_stats(test_collector)
    assert.spy(test_collector.get_raw_stats).was.called(1)
    assert.spy(test_collector.get_raw_stats).was.called_with(test_collector)
    assert.is_equal("test=7\n", stats)
  end)
end)
