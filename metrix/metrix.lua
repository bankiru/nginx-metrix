local version = '1.0-alpha'

local ngx_phases_handlers = {
    ['init'] = {},
    ['access'] = {},
    ['content'] = {},
    ['log'] = {},
    ['body-filter'] = {},
    ['header-filter'] = {},
    ['rewrite'] = {},
    ['ssl_certificate'] = {},
    ['init_worker'] = {},
}
local do_not_track = false

--------------------------------------------------------------------------------
-- Utils
--------------------------------------------------------------------------------

if _G.inspect == nil then
    _G.inspect = require('metrix.lib.inspect')
    _G.loginspect = function(...) ngx.log(ngx.STDERR, _G.inspect(...)) end
end

if _G.json == nil then
    local succ

    succ, _G.json = pcall(function()
        return require('cjson')
    end)

    if not succ then
        succ, _G.json = pcall(function()
            return require('json')
        end)
    end

    if not succ then
        error('Can not find lua json or cjson')
    end
end

if package.loaded['metrix.lib.fun'] == nil then
    require('metrix.lib.fun')()
end

if package.loaded['metrix.lib.functions'] == nil then
    require('metrix.lib.functions')
end

if _G.lust == nil then
    _G.lust = require('metrix.lib.lust')
end

--------------------------------------------------------------------------------
-- Loading
--------------------------------------------------------------------------------
local storage_tools = require('metrix.storage_tools')
local output_tools  = require('metrix.output_tools')(version)
local collectors    = require('metrix.collectors')(ngx_phases_handlers)

--------------------------------------------------------------------------------
-- Storage
--------------------------------------------------------------------------------

---
-- @param namespaces table
--
local init_namespaces = function(namespaces)
    assert(type(namespaces) == 'table', 'namespaces should be table, got' .. type(namespaces))

    storage_tools.set_namespaces(namespaces)
end

--------------------------------------------------------------------------------
-- Collectors functions
--------------------------------------------------------------------------------
local builtin_collectors = iter({[[request]], [[status]], [[upstream]]})

---
-- @param collector
---
local register_collector = function(collector)
    collector = collectors.register(collector, storage_tools, output_tools)

    iter(collector.ngx_phases):each(function(phase)
        table.insert(ngx_phases_handlers[phase], collector)
    end)
end

---
--
local register_builtin_collectors = function()
    builtin_collectors:each(function(name)
        local collector = require('metrix.collectors.' .. name)
        register_collector(collector)
    end)
end

--------------------------------------------------------------------------------
-- Handling nginx phases
--------------------------------------------------------------------------------

---
-- @param phase string
---
local handle_ngx_phase = function(phase)
    assert(type(phase) == 'string' and ngx_phases_handlers[phase] ~= nil,
        ('Invalid ngx phase %s (%s)'):format(inspect(phase), type(phase)))

    if do_not_track then
        do_not_track = false
    else
        storage_tools.set_namespace(ngx.var.server_name or ngx.var.hostname)
        each(function(collector) collector:handle_ngx_phase(phase) end, ngx_phases_handlers[phase])
    end
end

--------------------------------------------------------------------------------
-- Output
--------------------------------------------------------------------------------
local get_vhosts_json = function(namespaces)
    return json.encode(namespaces:totable())
end

local get_stats_json = function(namespaces)
    local stats = {}
    namespaces:each(function(namespace)
        storage_tools.set_namespace(namespace)

        stats[namespace] = collectors.all:reduce(
            function(stats, collector)
                if is_callable(collector.get_raw_stats) then
                    stats[collector.name] = collector:get_raw_stats():tomap()
                end
                return stats
            end,
            {}
        )
        stats[namespace].vhost = namespace

        storage_tools.reset_namespace()
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
    local stats = namespaces:reduce(
        function(namespace_stats, namespace)
            storage_tools.set_namespace(namespace)

            namespace_stats = collectors.all:reduce(
                function(collector_stats, collector)
                    if is_callable(collector.get_text_stats) then
                        collector_stats = collector_stats .. output_tools.text.section_template(collector:get_text_stats()):gen{namespace=namespace, collector=collector.name}
                    end
                    return collector_stats
                end,
                namespace_stats
            )

            storage_tools.reset_namespace()

            return namespace_stats
        end,
        ''
    )

    return output_tools.text.header() .. stats
end

local get_vhosts_html = function(namespaces)
    return output_tools.html.page_template(
        output_tools.html.section_template(
            lust{[[<ul class="list-group">@map{ vhost=vhosts }:{{<li class="list-group-item">$vhost</li>}}</ul>]]}:gen{vhosts=namespaces:totable()}
        ):gen{name='vhosts'}
    ):gen{}
end

local get_stats_html = function(namespaces)
    local is_many_namespaces = namespaces:length() > 1

    local content = namespaces:reduce(
        function(namespace_stats, namespace)
            storage_tools.set_namespace(namespace)

            local collectors_stats = collectors.all:reduce(
                function(collector_stats, collector)
                    if is_callable(collector.get_html_stats) then
                        collector_stats = collector_stats .. collector:get_html_stats()
                    end
                    return collector_stats
                end,
                ''
            )

            if is_many_namespaces then
                collectors_stats = output_tools.html.section_template(collectors_stats):gen{name=namespace, class='primary'}
            end

            storage_tools.reset_namespace()

            return namespace_stats .. collectors_stats
        end,
        ''
    )

    return output_tools.html.page_template(content):gen{}
end

---
-- @param _do_not_track bool default true
--
local show = function(_do_not_track)
    local namespaces = iter(storage_tools.get_namespaces())

    local content = ''
    local format = output_tools.get_format()

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

    output_tools.set_content_type_header()
    ngx.say(content)

    if _do_not_track ~= nil then
        do_not_track = _do_not_track
    else
        do_not_track = true
    end
end

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------
local exports = {}
exports.version = version
exports.init_shared_dict = storage_tools.init_shared_dict
exports.init_namespaces = init_namespaces
exports.register_collector = register_collector
exports.register_builtin_collectors = register_builtin_collectors
exports.handle_ngx_phase = handle_ngx_phase
exports.show = show

if __TEST__ then
    exports.__private__ = {
        collectors = collectors,
        ngx_phases_handlers = ngx_phases_handlers,
        storage_tools = storage_tools,
    }
end

setmetatable(exports, {
    __call = function(_, shared_dict, skip_register_builtin_collectors)
        storage_tools.init_shared_dict(shared_dict)

        if not skip_register_builtin_collectors then
            register_builtin_collectors()
        end

        return exports
    end,
})

return exports
