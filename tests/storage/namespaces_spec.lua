require('tests.bootstrap')(assert)

describe('storage.namespaces', function()

    local namespaces
    local dict_mock

    setup(function()
        package.loaded['nginx-metrix.storage.dict'] = nil
        package.loaded['nginx-metrix.storage.namespaces'] = nil
        dict_mock = mock(require 'nginx-metrix.storage.dict', true)
        package.loaded['nginx-metrix.storage.dict'] = dict_mock
        namespaces = require 'nginx-metrix.storage.namespaces'
    end)

    teardown(function()
        mock.revert(dict_mock)
        package.loaded['nginx-metrix.storage.dict'] = nil
        package.loaded['nginx-metrix.storage.namespaces'] = nil
    end)

    after_each(function()
        namespaces.__private__.set_list_cache({})
    end)

    it('init without namespaces list', function()
        assert.has_no.errors(function()
            namespaces.init({})
        end)

        assert.spy(dict_mock.set).was_not.called()
    end)

    it('init failed on invalid namespaces list type', function()
        assert.has_error(
            function()
                namespaces.init({namespaces = 123123123})
            end,
            'Invalid namespaces type. Expected table, got number.'
        )
    end)

    it('set/list', function()
        local test_list = { [[ns_set_list]] }

        local s = stub.new(dict_mock, 'get')
        s.on_call_with(namespaces.__private__.namespaces_list_key).returns(test_list)

        assert.has_no.errors(function()
            namespaces.set(test_list)
        end)

        assert.spy(dict_mock.get).was.called_with(namespaces.__private__.namespaces_list_key)
        assert.spy(dict_mock.set).was.called_with(namespaces.__private__.namespaces_list_key, test_list)

        local actual_list

        assert.has_no.errors(function()
            actual_list = namespaces.list()
        end)

        assert.spy(dict_mock.get).was.called_with(namespaces.__private__.namespaces_list_key)
        assert.is_table(actual_list)
        assert.is_same(test_list, actual_list)

        namespaces.set(test_list)
        namespaces.set(test_list)

        assert.spy(dict_mock.get).was.called(2)
        assert.spy(dict_mock.set).was.called(1)
    end)


    it('init with valid namespaces list', function()
        local test_list = { [[ns1]], [[ns2]] }

        stub.new(dict_mock, 'get').on_call_with(namespaces.__private__.namespaces_list_key).returns({})

        assert.has_no.errors(function()
            namespaces.init({ namespaces = test_list })
        end)

        assert.spy(dict_mock.get).was.called_with(namespaces.__private__.namespaces_list_key)
        assert.spy(dict_mock.set).was.called_with(namespaces.__private__.namespaces_list_key, test_list)
    end)


    it('active/activate/reset_active', function()
        local test_ns = 'ns_active'

        assert.is_nil(namespaces.active())

        assert.has_no.errors(function()
            namespaces.activate(test_ns)
        end)

        assert.is_equal(test_ns, namespaces.active())

        assert.has_no.errors(function()
            namespaces.reset_active()
        end)

        assert.is_nil(namespaces.active())
    end)
end)
