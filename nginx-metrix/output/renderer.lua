local json = require 'nginx-metrix.lib.json'
local output_helper = require 'nginx-metrix.output.helper'
local namespaces_module = require 'nginx-metrix.storage.namespaces'
local collectors = require 'nginx-metrix.collectors'
local lust = require 'Lust'

local get_vhosts_json = function(namespaces)
    return json.encode(namespaces:totable())
end

local get_stats_json = function(namespaces)
    local stats = {}
    namespaces:each(function(namespace)
        namespaces_module.activate(namespace)

        stats[namespace] = collectors.all:reduce(
            function(stats, collector)
                if is.callable(collector.get_raw_stats) then
                    stats[collector.name] = collector:get_raw_stats():tomap()
                end
                return stats
            end,
            {}
        )
        stats[namespace].vhost = namespace

        namespaces_module.reset_active()
    end)

    if namespaces:length() == 1 then
        stats = stats[namespaces:head()] or {}
    end

    stats['service'] = 'nginx-metrix'

    return json.encode(stats)
end

local get_vhosts_text = function(namespaces)
    return namespaces:reduce(
        function(str, namespace)
            return str .. "\n\t- " .. namespace
        end,
        'vhosts:'
    )
end

local get_stats_text = function(namespaces)
    local text = output_helper.text
    local stats = namespaces:reduce(
        function(namespace_stats, namespace)
            namespaces_module.activate(namespace)

            namespace_stats = collectors.all:reduce(
                function(collector_stats, collector)
                    if is.callable(collector.get_text_stats) then
                        collector_stats = collector_stats .. text.section_template(collector:get_text_stats(text)):gen{namespace=namespace, collector=collector.name}
                    end
                    return collector_stats
                end,
                namespace_stats
            )

            namespaces_module.reset_active()

            return namespace_stats
        end,
        ''
    )

    return text.header() .. stats
end

local get_vhosts_html = function(namespaces)
    return output_helper.html.page_template(
        output_helper.html.section_template(
            lust{[[<ul class="list-group">@map{ vhost=vhosts }:{{<li class="list-group-item">$vhost</li>}}</ul>]]}:gen{vhosts=namespaces:totable()}
        ):gen{name='vhosts'}
    ):gen{}
end

local get_stats_html = function(namespaces)
    local is_many_namespaces = namespaces:length() > 1
    local html = output_helper.html

    local content = namespaces:reduce(
        function(namespace_stats, namespace)
            namespaces_module.activate(namespace)

            local collectors_stats = collectors.all:reduce(
                function(collector_stats, collector)
                    if is.callable(collector.get_html_stats) then
                        collector_stats = collector_stats .. collector:get_html_stats(html)
                    end
                    return collector_stats
                end,
                ''
            )

            if is_many_namespaces then
                collectors_stats = html.section_template(collectors_stats):gen{name=namespace, class='primary'}
            end

            namespaces_module.reset_active()

            return namespace_stats .. collectors_stats
        end,
        ''
    )

    return html.page_template(content):gen{}
end

local render = function()
    local namespaces = iter(namespaces_module.list())

    local content = ''
    local format = output_helper.get_format()

    local list_vhosts = ngx.req.get_uri_args().list_vhosts ~= nil
    if list_vhosts then
        if format == 'json' then
            content = get_vhosts_json(namespaces)
        elseif format == 'text' then
            content = get_vhosts_text(namespaces)
        elseif format == 'html' then
            content = get_vhosts_html(namespaces)
        end
    else
        if ngx.req.get_uri_args().vhost ~= nil then
            namespaces = namespaces:grep(ngx.req.get_uri_args().vhost)
        end

        if format == 'json' then
            content = get_stats_json(namespaces)
        elseif format == 'text' then
            content = get_stats_text(namespaces)
        elseif format == 'html' then
            content = get_stats_html(namespaces)
        end
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
        get_stats_json  = get_stats_json,
        get_vhosts_text = get_vhosts_text,
        get_stats_text  = get_stats_text,
        get_vhosts_html = get_vhosts_html,
        get_stats_html  = get_stats_html,
    }
end


return exports