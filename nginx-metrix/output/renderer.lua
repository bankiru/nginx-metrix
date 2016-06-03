local json = require 'dkjson'
local output_helper = require 'nginx-metrix.output.helper'
local namespaces = require 'nginx-metrix.storage.namespaces'
local collectors = require 'nginx-metrix.collectors'
local lust = require 'Lust'

local get_vhosts_json = function(vhosts)
  return json.encode(vhosts:totable())
end

local get_stats_json = function(vhosts)
  local stats = {}
  vhosts:each(function(vhost)
    namespaces.activate(vhost)

    stats[vhost] = collectors.all:reduce(
      function(collectors_stats, collector)
        if is.callable(collector.get_raw_stats) then
          collectors_stats[collector.name] = collector:get_raw_stats():tomap()
        end
        return collectors_stats
      end,
      {}
    )
    stats[vhost].vhost = vhost

    namespaces.reset_active()
  end)

  if vhosts:length() == 1 then
    stats = stats[vhosts:head()] or {}
  end

  stats['service'] = 'nginx-metrix'

  return json.encode(stats)
end

local get_vhosts_text = function(vhosts)
  return vhosts:reduce(
    function(str, vhost)
      return str .. "\n\t- " .. vhost
    end,
    'vhosts:'
  )
end

local get_stats_text = function(vhosts)
  local text = output_helper.text
  local stats = vhosts:reduce(
    function(stats, vhost)
      namespaces.activate(vhost)

      stats = collectors.all:reduce(
        function(collector_stats, collector)
          if is.callable(collector.get_text_stats) then
            collector_stats = collector_stats .. text.section_template(collector:get_text_stats(text)):gen { namespace = vhost, collector = collector.name }
          end
          return collector_stats
        end,
        stats
      )

      namespaces.reset_active()

      return stats
    end,
    ''
  )

  return text.header() .. stats
end

local get_vhosts_html = function(vhosts)
  return output_helper.html.page_template(output_helper.html.section_template(lust { [[<ul class="list-group">@map{ vhost=vhosts }:{{<li class="list-group-item">$vhost</li>}}</ul>]] }:gen { vhosts = vhosts:totable() }):gen { name = 'vhosts' }):gen {}
end

local get_stats_html = function(vhosts)
  local is_many_vhosts = vhosts:length() > 1
  local html = output_helper.html

  local content = vhosts:reduce(
    function(vhost_stats, vhost)
      namespaces.activate(vhost)

      local collectors_stats = collectors.all:reduce(
        function(collector_stats, collector)
          if is.callable(collector.get_html_stats) then
            collector_stats = collector_stats .. collector:get_html_stats(html)
          end
          return collector_stats
        end,
        ''
      )

      if is_many_vhosts then
        collectors_stats = html.section_template(collectors_stats):gen { name = vhost, class = 'primary' }
      end

      namespaces.reset_active()

      return vhost_stats .. collectors_stats
    end,
    ''
  )

  return html.page_template(content):gen {}
end

local render_vhosts = function(vhosts)
  local format = output_helper.get_format()

  if format == 'json' then
    return get_vhosts_json(vhosts)
  end

  if format == 'text' then
    return get_vhosts_text(vhosts)
  end

  if format == 'html' then
    return get_vhosts_html(vhosts)
  end
end

local render_stats = function(vhosts)
  local format = output_helper.get_format()

  if format == 'json' then
    return get_stats_json(vhosts)
  end

  if format == 'text' then
    return get_stats_text(vhosts)
  end

  if format == 'html' then
    return get_stats_html(vhosts)
  end
end

local filter_vhosts = function(vhosts, filter)
  vhosts = iter(vhosts)

  if filter then
    local filter_func

    if type(filter) == 'string' then
      filter_func = function(vhost) return vhost:match(filter) end
    elseif type(filter) == 'table' then
      filter_func = function(vhost) return index(vhost, filter) ~= nil end
    elseif type(filter) == 'function' then
      filter_func = filter
    else
      filter_func = function() return true end
    end

    vhosts = vhosts:filter(filter_func)
  end

  return vhosts
end

local render = function(options)
  local vhosts = filter_vhosts(namespaces.list(), options.vhosts_filter)

  local content

  if ngx.req.get_uri_args().list_vhosts ~= nil then
    content = render_vhosts(vhosts)
  else
    if ngx.req.get_uri_args().vhost ~= nil then
      vhosts = filter_vhosts(vhosts, '^' .. ngx.req.get_uri_args().vhost:gsub("([().%+-*?[^$])", "[%1]") .. '$')
    end
    content = render_stats(vhosts)
  end

  output_helper.set_content_type_header()
  ngx.say(content)
end

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------

local exports = {}
exports.render = render

if __TEST__ then
  exports.__private__ = {
    get_vhosts_json = get_vhosts_json,
    get_stats_json = get_stats_json,
    get_vhosts_text = get_vhosts_text,
    get_stats_text = get_stats_text,
    get_vhosts_html = get_vhosts_html,
    get_stats_html = get_stats_html,
    filter_vhosts = filter_vhosts,
    render_vhosts = render_vhosts,
    render_stats = render_stats,
  }
end


return exports
