require('tests.bootstrap')(assert)

describe('collectors', function()

  local collectors

  setup(function()
    collectors = require 'nginx-metrix.collectors';
  end)

  teardown(function()
    package.loaded['nginx-metrix.collectors'] = nil
  end)

  after_each(function()
    collectors.__private__.collectors({})
  end)

  it('collector_exists', function()
    assert.is_false(collectors.__private__.collector_exists({ name = 'test-collector' }))

    collectors.__private__.collectors({ { name = 'test-collector' } })

    assert.is_true(collectors.__private__.collector_exists({ name = 'test-collector' }))
  end)

  local validate_data_provider = {
    {
      collector = nil,
      error = 'Collector MUST be a table, got nil: nil',
    },
    {
      collector = 'invalid collector type',
      error = 'Collector MUST be a table, got string: "invalid collector type"',
    },
    {
      collector = {},
      error = 'Collector must have string property "name", got nil: {}',
    },
    {
      collector = { name = 13 },
      error = "Collector must have string property \"name\", got number: {\n  name = 13\n}",
    },
    {
      collector = { name = 'existent-collector' },
      error = 'Collector<existent-collector> already exists',
    },
    {
      collector = {
        name = 'test-collector',
        ngx_phases = nil,
      },
      error = 'Collector<test-collector>.ngx_phases must be an array, given: nil',
    },
    {
      collector = {
        name = 'test-collector',
        ngx_phases = 'invalid type',
      },
      error = 'Collector<test-collector>.ngx_phases must be an array, given: string',
    },
    {
      collector = {
        name = 'test-collector',
        ngx_phases = { [[valid phase]], 13 },
      },
      error = 'Collector<test-collector>.ngx_phases must be an array of strings, given: { "valid phase", 13 }',
    },
    {
      collector = {
        name = 'test-collector',
        ngx_phases = { [[valid phase]] },
        on_phase = 'invalid type',
      },
      error = 'Collector<test-collector>:on_phase must be a function or callable table, given: string',
    },
    {
      collector = {
        name = 'test-collector',
        ngx_phases = { [[valid phase]] },
        on_phase = function() end,
        fields = 'invalid type',
      },
      error = 'Collector<test-collector>.fields must be a table, given: string',
    },
    {
      collector = {
        name = 'test-collector',
        ngx_phases = { [[valid phase]] },
        on_phase = function() end,
        fields = { testfield = 'invalid type' },
      },
      error = "Collector<test-collector>.fields must be an table[string, table], given: {\n  testfield = \"invalid type\"\n}",
    },
  }

  for k, data in pairs(validate_data_provider) do
    it('collector_validate failed #' .. k, function()
      collectors.__private__.collectors({ { name = 'existent-collector' } })

      assert.has_error(function()
        collectors.__private__.collector_validate(data.collector)
      end,
        data.error)
    end)
  end

  it('collector_validate', function()
    local test_collector = {
      name = 'test-collector',
      ngx_phases = { [[valid phase]] },
      on_phase = function() end,
      fields = { testfield = {} },
    }

    assert.has_no.errors(function()
      collectors.__private__.collector_validate(test_collector)
    end)
  end)

  it('collector_extend', function()
    local test_collector = {
      name = 'test-collector',
      ngx_phases = { [[valid phase]] },
      on_phase = function() end,
      fields = { testfield = {} },
    }

    local extended_test_collector = collectors.__private__.collector_extend(test_collector)

    assert.is_same(test_collector, extended_test_collector)

    local metatable = getmetatable(extended_test_collector)
    assert.is_table(metatable)
    assert.is_table(metatable.__index)
    assert.is_equal(metatable, metatable.__index)
    assert.is_function(metatable.init)
    assert.is_function(metatable.handle_ngx_phase)
    assert.is_function(metatable.aggregate)
    assert.is_function(metatable.get_raw_stats)
    assert.is_function(metatable.get_text_stats)
    assert.is_function(metatable.get_html_stats)
  end)

  it('register', function()
    local test_collector = {
      name = 'test-collector',
      ngx_phases = { [[valid phase]] },
      on_phase = function() end,
      fields = { testfield = {} },
    }

    local extended_test_collector = collectors.register(test_collector)
    assert.is_same(test_collector, extended_test_collector)

    assert.is_same({ test_collector }, collectors.__private__.collectors())
  end)

  it('all', function()
    local test_collectors = { { name = 'existent-collector' } }
    collectors.__private__.collectors(test_collectors)

    assert.is_table(collectors.all)
    assert.is_function(collectors.all.totable)
    assert.is_same(test_collectors, collectors.all:totable {})
  end)
end)
