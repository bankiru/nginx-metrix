require('tests.bootstrap')(assert)

describe('logger', function()

    local logger

    setup(function()
        local ngx = {
            log = function() end,
            ERROR = 'ERROR',
            STDERR = 'STDERR'
        }
        _G.ngx = mock(ngx, true)

        logger = require 'nginx-metrix.logger';
    end)

    teardown(function()
        _G.ngx = nil
    end)

    it('log', function()
        logger.log('err', 'msg')
        assert.spy(_G.ngx.log).was.called_with('err', 'msg')

        logger.log('err', {msg='msg'})
        assert.spy(_G.ngx.log).was.called_with('err', "{\n  msg = \"msg\"\n}")
    end)

    it('error', function()
        logger.error('msg')
        assert.spy(_G.ngx.log).was.called_with('ERROR', 'msg')
    end)

    it('stderror', function()
        logger.stderror('msg')
        assert.spy(_G.ngx.log).was.called_with('STDERR', 'msg')
    end)

end)
