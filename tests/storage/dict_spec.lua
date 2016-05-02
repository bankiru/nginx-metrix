require('tests.bootstrap')(assert)

describe('storage.dict', function()
    local dict = require 'nginx-metrix.storage.dict'
    local ngx_mock = require 'tests.ngx_mock'()
    local match = require 'luassert.match'

    local mk_test_dict = function(name)
        local shared_dict = ngx_mock.define_shared_dict(name or 'test-dict')
        dict.init({shared_dict = shared_dict})

        return shared_dict
    end

    setup(function()
        package.loaded['nginx-metrix.storage.dict'] = nil
        ngx_mock.reset()
    end)

    teardown(function()
        ngx_mock.reset()
    end)

    before_each(function()
        ngx_mock.reset()
        dict = require 'nginx-metrix.storage.dict'
    end)

    after_each(function()
        package.loaded['nginx-metrix.storage.dict'] = nil
    end)

    it('init failed on wrong shared_dict name', function()
        assert.has_error(
            function()
                dict.init({shared_dict = 'non-existent-shared-dict'})
            end,
            'lua_shared_dict "non-existent-shared-dict" does not defined.'
        )
    end)

    it('init failed on invalid shared_dict type', function()
        assert.has_error(
            function()
                dict.init({shared_dict = 123123123})
            end,
            'Invalid shared_dict type. Expected string or table, got number.'
        )
    end)

    it('init by shared_dict instance', function()
        local shared_dict = ngx_mock.define_shared_dict('test-dict')

        assert.has_no.errors(function()
            dict.init({shared_dict = shared_dict})
        end)

        assert.is_table(dict._shared)
        assert.is_same(dict._shared, shared_dict)

        local metatable = getmetatable(dict)
        assert.is_table(metatable)
        assert.is_function(metatable.__index)
    end)

    it('init by name', function()
        ngx_mock.define_shared_dict('test-dict')

        assert.has_no.errors(function()
            dict.init({shared_dict = 'test-dict'})
        end)

        assert.is_table(dict._shared)

        local metatable = getmetatable(dict)
        assert.is_table(metatable)
        assert.is_function(metatable.__index)
    end)

    it('normalize key', function()
        assert.has_error(
            function()
                dict.__private__.normalize_key(nil)
            end,
            'key can not be nil'
        )

        local normalized_key = dict.__private__.normalize_key(777)
        assert.is_string(normalized_key)
        assert.are.equal(normalized_key, '777')

        local normalized_key = dict.__private__.normalize_key({})
        assert.is_string(normalized_key)
        assert.matches('table: 0x[0-9a-f]+', normalized_key)
    end)

    it('get', function()
        local shared_dict = mk_test_dict()

        shared_dict:set('get-test-key', 'get-test-value')

        spy.on(shared_dict, 'get')
        local actual_value, actual_flags = dict.get('get-test-key')
        assert.spy(shared_dict.get).was_called_with(shared_dict, 'get-test-key')
        assert.are.equal('get-test-value', actual_value)
        assert.are.equal(0, actual_flags)
    end)

    it('get_stale', function()
        local shared_dict = mk_test_dict()

        shared_dict:set('get_stale-test-key', 'get_stale-test-value')

        spy.on(shared_dict, 'get_stale')
        local actual_value, actual_flags, actual_stale = dict.get_stale('get_stale-test-key')
        assert.spy(shared_dict.get_stale).was_called_with(shared_dict, 'get_stale-test-key')
        assert.are.equal('get_stale-test-value', actual_value)
        assert.are.equal(0, actual_flags)
        assert.is_false(actual_stale)
    end)

    it('set', function()
        local shared_dict = mk_test_dict()
        local _ = match._

        spy.on(shared_dict, 'set')
        local result = dict.set('set-test-key', 'set-test-value')
        assert.spy(shared_dict.set).was.called_with(_, 'set-test-key', 'set-test-value', _, _)
        assert.spy(shared_dict.set).was.returned_with(true, nil, false)
        assert.is_true(result)
    end)

    it('safe_set', function()
        local shared_dict = mk_test_dict()
        local _ = match._

        spy.on(shared_dict, 'safe_set')
        local result = dict.safe_set('safe_set-test-key', 'safe_set-test-value')
        assert.spy(shared_dict.safe_set).was.called_with(_, 'safe_set-test-key', 'safe_set-test-value', _, _)
        assert.spy(shared_dict.safe_set).was.returned_with(true, nil)
        assert.is_true(result)
    end)

    it('add', function()
        local shared_dict = mk_test_dict()
        local _ = match._

        spy.on(shared_dict, 'add')
        local result = dict.add('add-test-key', 'add-test-value')
        assert.spy(shared_dict.add).was.called_with(_, 'add-test-key', 'add-test-value', _, _)
        assert.spy(shared_dict.add).was.returned_with(true, nil, false)
        assert.is_true(result)
    end)

    it('safe_add', function()
        local shared_dict = mk_test_dict()
        local _ = match._

        spy.on(shared_dict, 'safe_add')
        local result = dict.safe_add('safe_add-test-key', 'safe_add-test-value')
        assert.spy(shared_dict.safe_add).was.called_with(_, 'safe_add-test-key', 'safe_add-test-value', _, _)
        assert.spy(shared_dict.safe_add).was.returned_with(true, nil)
        assert.is_true(result)
    end)

    it('incr failed with not found', function()
        local shared_dict = mk_test_dict()
        local _ = match._

        spy.on(shared_dict, 'incr')
        local result, err = dict.incr('incr-test-key', 1)
        assert.spy(shared_dict.incr).was.called_with(_, 'incr-test-key', 1)
        assert.spy(shared_dict.incr).was.returned_with(nil, 'not found')
        assert.is_nil(result)
        assert.are.equal('not found', err)
    end)

    it('incr', function()
        local shared_dict = mk_test_dict()
        local _ = match._

        shared_dict:set('incr-test-key', 1)

        spy.on(shared_dict, 'incr')
        local result, err = dict.incr('incr-test-key', 1)
        assert.spy(shared_dict.incr).was.called_with(_, 'incr-test-key', 1)
        assert.spy(shared_dict.incr).was.returned_with(2, nil)
        assert.are.equal(2, result)
        assert.is_nil(err)
    end)

    it('safe_incr', function()
        local shared_dict = mk_test_dict()
        local _ = match._

        spy.on(shared_dict, 'add')
        local result, err = dict.safe_incr('incr-test-key', 2)
        assert.spy(shared_dict.add).was.called_with(_, 'incr-test-key', 2, _, _)
        assert.are.equal(2, result)
        assert.is_nil(err)

        spy.on(shared_dict, 'incr')
        local result, err = dict.safe_incr('incr-test-key', 2)
        assert.spy(shared_dict.incr).was.called_with(_, 'incr-test-key', 2)
        assert.are.equal(4, result)
        assert.is_nil(err)
    end)

    it('replace failed with not found', function()
        local shared_dict = mk_test_dict()
        local _ = match._

        spy.on(shared_dict, 'replace')
        local result, err = dict.replace('replace-test-key', 'replace-test-value')
        assert.spy(shared_dict.replace).was.called_with(_, 'replace-test-key', 'replace-test-value', _, _)
        assert.spy(shared_dict.replace).was.returned_with(false, 'not found')
        assert.is_false(result)
        assert.are.equal('not found', err)
    end)

    it('replace', function()
        local shared_dict = mk_test_dict()
        local _ = match._

        shared_dict:set('replace-test-key', 'previous')

        spy.on(shared_dict, 'replace')
        local result, err = dict.replace('replace-test-key', 'replace-test-value')
        assert.spy(shared_dict.replace).was.called_with(_, 'replace-test-key', 'replace-test-value', _, _)
        assert.spy(shared_dict.replace).was.returned_with(true, nil, false)
        assert.is_true(result)
        assert.is_nil(err)
        local actual_value = shared_dict:get('replace-test-key')
        assert.are.equal('replace-test-value', actual_value)
    end)

    it('delete', function()
        local shared_dict = mk_test_dict()
        local _ = match._

        shared_dict:set('delete-test-key', 'delete-test-value')

        spy.on(shared_dict, 'delete')
        dict.delete('delete-test-key')
        assert.spy(shared_dict.delete).was.called_with(_, 'delete-test-key')
        local actual_value = shared_dict:get('delete-test-key')
        assert.is_nil(actual_value)
    end)

    it('flush_all', function()
        local shared_dict = mk_test_dict()

        spy.on(shared_dict, 'flush_expired')
        dict.flush_expired()
        assert.spy(shared_dict.flush_expired).was.called()
    end)

    it('flush_expired', function()
        local shared_dict = mk_test_dict()

        spy.on(shared_dict, 'flush_expired')
        dict.flush_expired()
        assert.spy(shared_dict.flush_expired).was.called()
    end)

    it('get_keys', function()
        local shared_dict = mk_test_dict()

        spy.on(shared_dict, 'get_keys')
        dict.get_keys()
        assert.spy(shared_dict.get_keys).was.called()
    end)

end)
