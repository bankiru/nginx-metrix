require('tests.bootstrap')(assert)

describe('collectors.upstream', function()
    local collector

    setup(function()
        package.loaded['nginx-metrix.collectors.upstream'] = nil
        collector = require 'nginx-metrix.collectors.upstream'
        collector.storage = mock({cyclic_incr = function() end, mean_add = function() end,}, true)
    end)

    teardown(function()
        collector = nil
        package.loaded['nginx-metrix.collectors.upstream'] = nil
        _G.ngx = nil
    end)

    after_each(function()
        mock.clear(collector.storage)
    end)

    -- tests
    it('valid structure', function()
        assert.is_equal('upstream', collector.name)
        assert.is_table(collector.fields)
        assert.is_table(collector.fields.rps)
        assert.is_table(collector.fields.connect_time)
        assert.is_table(collector.fields.header_time)
        assert.is_table(collector.fields.response_time)

        assert.is_table(collector.ngx_phases)
        assert.is_function(collector.on_phase)
    end)

    it('handles phase log skipped', function()
        _G.ngx = {
            var = {
                upstream_addr = nil,
            },
        }
        collector:on_phase('log')

        assert.spy(collector.storage.cyclic_incr).was_not.called()
        assert.spy(collector.storage.mean_add).was_not.called()
    end)

    it('handles phase log #1', function()
        _G.ngx = {
            var = {
                upstream_addr = '127.0.0.1',
                upstream_connect_time = 1,
                upstream_header_time = 2,
                upstream_response_time = 3,
            },
        }
        collector:on_phase('log')

        assert.spy(collector.storage.cyclic_incr).was.called_with(collector.storage, 'rps')
        assert.spy(collector.storage.cyclic_incr).was.called(1)
        assert.spy(collector.storage.mean_add).was.called_with(collector.storage, 'connect_time', 1)
        assert.spy(collector.storage.mean_add).was.called_with(collector.storage, 'header_time', 2)
        assert.spy(collector.storage.mean_add).was.called_with(collector.storage, 'response_time', 3)
        assert.spy(collector.storage.mean_add).was.called(3)
    end)

    it('handles phase log #2', function()
        _G.ngx = {
            var = {
                upstream_addr = '127.0.0.1',
                upstream_connect_time = '-',
                upstream_header_time = '-',
                upstream_response_time = '-',
            },
        }
        collector:on_phase('log')

        assert.spy(collector.storage.cyclic_incr).was.called_with(collector.storage, 'rps')
        assert.spy(collector.storage.cyclic_incr).was.called(1)
        assert.spy(collector.storage.mean_add).was_not.called()
    end)
end)
