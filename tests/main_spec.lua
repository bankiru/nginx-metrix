require('tests.bootstrap')(assert)

describe('main', function()
    local match = require 'luassert.match'

    after_each(function()
        if package.loaded then
            grep('^nginx[-]metrix[.].+', package.loaded):each(function(k, _)
                package.loaded[k] = nil
            end)
        end
    end)

    -- tests
    it('register_collector', function()
        local test_collector = {name='test collector'}

        local collectors = mock(require 'nginx-metrix.collectors', true)
        local listener   = mock(require 'nginx-metrix.listener', true)
        local scheduler  = mock(require 'nginx-metrix.scheduler', true)

        local metrix = require 'nginx-metrix.main'
        collectors.register.on_call_with(test_collector).returns(test_collector)

        metrix.register_collector(test_collector)

        assert.spy(collectors.register).was.called(1)
        assert.spy(collectors.register).was.called_with(test_collector)

        assert.spy(listener.attach_collector).was.called(1)
        assert.spy(listener.attach_collector).was.called_with(test_collector)

        assert.spy(scheduler.attach_collector).was.called(1)
        assert.spy(scheduler.attach_collector).was.called_with(test_collector)
    end)

    it('register_builtin_collectors', function()
        local metrix = require 'nginx-metrix.main'
        spy.on(metrix, 'register_collector')

        metrix:register_builtin_collectors()

        assert.spy(metrix.register_collector).was.called(3)
        assert.spy(metrix.register_collector).was.called_with(match.is_table())
    end)

    it('init #1', function()
        local options = {
            skip_register_builtin_collectors = true,
            shared_dict = {},
        }
        local dict_mock = mock(require 'nginx-metrix.storage.dict', true)
        local namespaces_mock = mock(require 'nginx-metrix.storage.namespaces', true)

        local metrix = require 'nginx-metrix.main'

        spy.on(metrix, 'register_builtin_collectors')

        assert.has_no.errors(function()
            metrix = metrix(options)
        end)

        assert.spy(dict_mock.init).was.called(1)
        assert.spy(dict_mock.init).was.called_with(options)
        assert.spy(namespaces_mock.init).was_not.called()
        assert.spy(metrix.register_builtin_collectors).was_not.called()
    end)

    it('init #2', function()

        local vhosts = {[[vhost1]], [[vhost2]]}
        local options = {
            skip_register_builtin_collectors = false,
            shared_dict = {},
            vhosts = vhosts,
        }
        local dict_mock = mock(require 'nginx-metrix.storage.dict', true)
        local namespaces_mock = mock(require 'nginx-metrix.storage.namespaces', true)

        local metrix = require 'nginx-metrix.main'

        spy.on(metrix, 'register_builtin_collectors')

        assert.has_no.errors(function()
            metrix = metrix(options)
        end)

        assert.spy(dict_mock.init).was.called(1)
        assert.spy(dict_mock.init).was.called_with(options)
        assert.spy(namespaces_mock.init).was.called(1)
        assert.spy(namespaces_mock.init).was.called_with({namespaces=vhosts})
        assert.spy(metrix.register_builtin_collectors).was.called(1)
    end)

    it('init_scheduler', function()
        local scheduler  = mock(require 'nginx-metrix.scheduler', true)

        local metrix = require 'nginx-metrix.main'
        metrix.init_scheduler()

        assert.spy(scheduler.start).was.called(1)
    end)

    it('handle_ngx_phase and show', function()
        local ngx_mock = require 'tests.ngx_mock'()

        local shared_dict = ngx_mock.define_shared_dict('test-behavior-dict')

        local metrix = require 'nginx-metrix.main'({
            skip_register_builtin_collectors = true,
            shared_dict = shared_dict,
            vhosts = {'first.com', 'second.com', 'third.com'}
        })

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

        ngx.req.__URI_ARGS__.format = 'json'

        stub(ngx, 'say')

        metrix.show({vhosts_filter='.*'})
        metrix.handle_ngx_phase('log')
        assert.spy(ngx.say).was.called(1)
        assert.spy(ngx.say).was.called_with(match.json_equal({
            ['service'] = "nginx-metrix",
            ['first.com'] = {['test-collector'] = {['testfield'] = 0},['vhost'] = "first.com"},
            ['second.com'] = {['test-collector'] = {['testfield'] = 0},['vhost'] = "second.com"},
            ['third.com'] = {['test-collector'] = {['testfield'] = 0},['vhost'] = "third.com"},
        }))
        ngx.say:revert()

        stub(ngx, 'say')

        metrix.show({vhosts_filter='first.com'})
        metrix.handle_ngx_phase('log')
        assert.spy(ngx.say).was.called(1)
        assert.spy(ngx.say).was.called_with(match.json_equal({
            ['service'] = "nginx-metrix",
            ['test-collector'] = {['testfield'] = 0},
            ['vhost'] = "first.com",
        }))
        ngx.say:revert()

        metrix.handle_ngx_phase('log')

    end)
end)
