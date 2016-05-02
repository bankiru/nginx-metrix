require('tests.bootstrap')(assert)

describe('storage.collector_wrapper_factory', function()

    local namespaces
    local dict_mock
    local factory

    local mk_wrapper_metatable_mock = function(name)
        local wrapper_metatable = copy(factory.__private__.wrapper_metatable)
        if name ~= nil then
            wrapper_metatable.collector_name = 'collector_mock'
        end
        return wrapper_metatable
    end

    setup(function()
        package.loaded['nginx-metrix.storage.dict'] = nil
        dict_mock = mock(require 'nginx-metrix.storage.dict', true)
        package.loaded['nginx-metrix.storage.dict'] = dict_mock

        package.loaded['nginx-metrix.storage.namespaces'] = nil
        namespaces = require 'nginx-metrix.storage.namespaces'

        package.loaded['nginx-metrix.storage.collector_wrapper_factory'] = nil
        factory = require 'nginx-metrix.storage.collector_wrapper_factory'
    end)

    teardown(function()
        mock.revert(dict_mock)
        package.loaded['nginx-metrix.storage.dict'] = nil

        package.loaded['nginx-metrix.storage.collector_wrapper_factory'] = nil
    end)

    after_each(function()
        namespaces.reset_active()
    end)

    it('create', function()
        local collector_mock = {name = 'collector_mock' }

        local wrapper
        assert.has_no.errors(function()
            wrapper = factory.create(collector_mock)
        end)

        assert.is_table(wrapper)
        assert.is_equal(collector_mock.name, wrapper.collector_name)
        assert.is_same(factory.__private__.wrapper_metatable, getmetatable(wrapper))
    end)

    it('wrapper_metatable.prepare_key failed with nil key', function()
        local wrapper_metatable = mk_wrapper_metatable_mock()

        assert.has_error(
            function()
                wrapper_metatable:prepare_key(nil)
            end,
            'key can not be nil'
        )
    end)

    it('wrapper_metatable.prepare_key', function()
        local wrapper_metatable = mk_wrapper_metatable_mock()

        local actual_value = wrapper_metatable:prepare_key('test-key-1')
        assert.is_equal('test-key-1', actual_value)

        wrapper_metatable.collector_name = 'collector_mock'

        local actual_value = wrapper_metatable:prepare_key('test-key-2')
        assert.is_equal('collector_mock¦test-key-2', actual_value)

        namespaces.activate('test-namespace')
        local actual_value = wrapper_metatable:prepare_key('test-key-3')
        assert.is_equal('test-namespaceːcollector_mock¦test-key-3', actual_value)
    end)

    it('wrapper_metatable.get', function()
        local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

        wrapper_metatable:get('test-key')
        assert.spy(dict_mock.get).was.called_with('collector_mock¦test-key')
    end)

    it('wrapper_metatable.get_stale', function()
        local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

        wrapper_metatable:get_stale('test-key')
        assert.spy(dict_mock.get_stale).was.called_with('collector_mock¦test-key')
    end)

    it('wrapper_metatable.set', function()
        local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

        wrapper_metatable:set('test-key', 1, 1313, 13)
        assert.spy(dict_mock.set).was.called_with('collector_mock¦test-key', 1, 1313, 13)
    end)

    it('wrapper_metatable.safe_set', function()
        local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

        wrapper_metatable:safe_set('test-key', 1, 1313, 13)
        assert.spy(dict_mock.safe_set).was.called_with('collector_mock¦test-key', 1, 1313, 13)
    end)

    it('wrapper_metatable.add', function()
        local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

        wrapper_metatable:add('test-key', 1, 1313, 13)
        assert.spy(dict_mock.add).was.called_with('collector_mock¦test-key', 1, 1313, 13)
    end)

    it('wrapper_metatable.safe_add', function()
        local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

        wrapper_metatable:safe_add('test-key', 1, 1313, 13)
        assert.spy(dict_mock.safe_add).was.called_with('collector_mock¦test-key', 1, 1313, 13)
    end)

    it('wrapper_metatable.replace', function()
        local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

        wrapper_metatable:replace('test-key', 1, 1313, 13)
        assert.spy(dict_mock.replace).was.called_with('collector_mock¦test-key', 1, 1313, 13)
    end)

    it('wrapper_metatable.delete', function()
        local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

        wrapper_metatable:delete('test-key')
        assert.spy(dict_mock.delete).was.called_with('collector_mock¦test-key')
    end)

    it('wrapper_metatable.incr', function()
        local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

        wrapper_metatable:incr('test-key', 13)
        assert.spy(dict_mock.incr).was.called_with('collector_mock¦test-key', 13)
    end)

    it('wrapper_metatable.safe_incr', function()
        local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

        wrapper_metatable:safe_incr('test-key', 13)
        assert.spy(dict_mock.safe_incr).was.called_with('collector_mock¦test-key', 13)
    end)
end)