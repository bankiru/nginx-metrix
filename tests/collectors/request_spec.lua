require('tests.bootstrap')(assert)

describe('collectors.request', function()
    local collector

    setup(function()
        package.loaded['nginx-metrix.collectors.request'] = nil
        collector = require 'nginx-metrix.collectors.request'
        collector.storage = mock({safe_incr = function() end}, true)
    end)

    teardown(function()
        collector = nil
        package.loaded['nginx-metrix.collectors.request'] = nil
        _G.ngx = nil
    end)

    after_each(function()
        mock.clear(collector.storage)
    end)

    -- tests
    it('valid structure', function()
        assert.is_equal('request', collector.name)
        assert.is_table(collector.fields)
        assert.is_table(collector.fields.count)
        assert.is_table(collector.fields.total_time)
        assert.is_table(collector.fields.internal_count)
        assert.is_table(collector.fields.https_count)
        assert.is_table(collector.fields.total_length)

        assert.is_table(collector.ngx_phases)
        assert.is_function(collector.on_phase)
    end)

    it('handles phase log #1', function()
        _G.ngx = {
            status = 200,
            var = {
                request_time = 0.01,
                https = 'off',
                request_length = nil,
            },
            req = {
                is_internal = function() return false end,
            },
        }
        collector:on_phase('log')

        assert.spy(collector.storage.safe_incr).was.called_with(collector.storage, 'count')
        assert.spy(collector.storage.safe_incr).was.called_with(collector.storage, 'total_time', 0.01)
        assert.spy(collector.storage.safe_incr).was.called(2)
    end)

    it('handles phase log #2', function()
        _G.ngx = {
            status = 200,
            var = {
                request_time = 0.01,
                https = 'off',
                request_length = nil,
            },
            req = {
                is_internal = function() return true end,
            },
        }
        collector:on_phase('log')

        assert.spy(collector.storage.safe_incr).was.called_with(collector.storage, 'count')
        assert.spy(collector.storage.safe_incr).was.called_with(collector.storage, 'total_time', 0.01)
        assert.spy(collector.storage.safe_incr).was.called_with(collector.storage, 'internal_count')
        assert.spy(collector.storage.safe_incr).was.called(3)
    end)

    it('handles phase log #3', function()
        _G.ngx = {
            status = 200,
            var = {
                request_time = 0.01,
                https = 'on',
                request_length = nil,
            },
            req = {
                is_internal = function() return false end,
            },
        }
        collector:on_phase('log')

        assert.spy(collector.storage.safe_incr).was.called_with(collector.storage, 'count')
        assert.spy(collector.storage.safe_incr).was.called_with(collector.storage, 'total_time', 0.01)
        assert.spy(collector.storage.safe_incr).was.called_with(collector.storage, 'https_count')
        assert.spy(collector.storage.safe_incr).was.called(3)
    end)

    it('handles phase log #4', function()
        _G.ngx = {
            status = 200,
            var = {
                request_time = 0.01,
                https = 'off',
                request_length = 123,
            },
            req = {
                is_internal = function() return false end,
            },
        }
        collector:on_phase('log')

        assert.spy(collector.storage.safe_incr).was.called_with(collector.storage, 'count')
        assert.spy(collector.storage.safe_incr).was.called_with(collector.storage, 'total_time', 0.01)
        assert.spy(collector.storage.safe_incr).was.called_with(collector.storage, 'total_length', 123)
        assert.spy(collector.storage.safe_incr).was.called(3)
    end)
end)
