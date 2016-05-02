require('tests.bootstrap')(assert)

describe('metrix collector statuses tests : ', function()
    local metrix

    local ngx_mock = require 'tests.ngx_mock'()

    local match = require 'luassert.match'

    local function eq_json(state, arguments)
        return function(value)
            local json = require 'nginx-metrix.lib.json'
            local util = require 'luassert.util'
            value =  json.decode(value)
            return util.deepcompare(value, arguments[1], true)
        end
    end
    assert:register("matcher", "eq_json", eq_json)

    setup(function()
        package.loaded['nginx-metrix.main'] = nil
    end)

    teardown(function()
        iter(package.loaded):each(function(k, _)
            if k:match('^nginx[-]metrix[.].+') then
                package.loaded[k] = nil
            end
        end)
    end)

    before_each(function()
        local shared_dict = ngx_mock.define_shared_dict('test-behavior-dict')
        metrix = require 'nginx-metrix.main'({
            skip_register_builtin_collectors = true,
            shared_dict = shared_dict,
        })
    end)

    after_each(function()
        ngx_mock.reset()
    end)

    -- tests
    it('whole process', function()
        local test_collector = mock({
            name = 'test-collector',
            ngx_phases = {[[log]]},
            on_phase = function() end,
            fields = {testfield = {}},
        })

        metrix.register_collector(test_collector)

        ngx.var.hostname = 'first.com'
        metrix.handle_ngx_phase('log')
        metrix.handle_ngx_phase('log')
        ngx.var.hostname = 'second.com'
        metrix.handle_ngx_phase('log')

        assert.spy(test_collector.on_phase).was.called_with(test_collector, 'log')
        assert.spy(test_collector.on_phase).was.called(3)

        stub(ngx, 'say')

        ngx.req.__URI_ARGS__.format = 'json'
        metrix.show()
        assert.spy(ngx.say).was.called(1)
        assert.spy(ngx.say).was.called_with(match.eq_json({['second.com'] = {['test-collector'] = {['testfield'] = 0},['vhost'] = "second.com"},['service'] = "nginx-metrix",['first.com'] = {['test-collector'] = {['testfield'] = 0},['vhost'] = "first.com"}}))
        ngx.say:revert()
    end)
end)
