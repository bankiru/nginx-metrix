require('tests.bootstrap')(assert)

describe('logger', function()

    local logger

    setup(function()
        local ngx = {
            log    = function() end,
            STDERR = 'STDERR',
            EMERG  = 'EMERG',
            ALERT  = 'ALERT',
            CRIT   = 'CRIT',
            ERR    = 'ERR',
            WARN   = 'WARN',
            NOTICE = 'NOTICE',
            INFO   = 'INFO',
            DEBUG  = 'DEBUG',
        }
        _G.ngx = mock(ngx)

        logger = require 'nginx-metrix.logger';
    end)

    after_each(function()
        mock.clear(_G.ngx)
    end)

    teardown(function()
        _G.ngx = nil
    end)

    it('log', function()
        logger.log(ngx.INFO, 'msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.INFO, 'msg')

        logger.log(ngx.INFO, { msg = 'msg' })
        assert.spy(_G.ngx.log).was.called_with(ngx.INFO, "{\n  msg = \"msg\"\n}")

        logger.log(ngx.INFO, 'msg', 'another arg')
        assert.spy(_G.ngx.log).was.called_with(ngx.INFO, 'msg :: { "another arg" }')

        assert.spy(_G.ngx.log).was.called(3)
    end)

    it('stderr', function()
        logger.stderr('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.STDERR, 'msg')

        logger.stderror('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.STDERR, 'msg')

        assert.spy(_G.ngx.log).was.called(2)
    end)

    it('emerg', function()
        logger.emerg('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.EMERG, 'msg')

        logger.emergency('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.EMERG, 'msg')

        assert.spy(_G.ngx.log).was.called(2)
    end)

    it('alert', function()
        logger.alert('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.ALERT, 'msg')

        assert.spy(_G.ngx.log).was.called(1)
    end)

    it('crit', function()
        logger.crit('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.CRIT, 'msg')

        logger.critical('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.CRIT, 'msg')

        assert.spy(_G.ngx.log).was.called(2)
    end)

    it('err', function()
        logger.err('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.ERR, 'msg')

        logger.error('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.ERR, 'msg')

        assert.spy(_G.ngx.log).was.called(2)
    end)

    it('warn', function()
        logger.warn('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.WARN, 'msg')

        logger.warning('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.WARN, 'msg')

        assert.spy(_G.ngx.log).was.called(2)
    end)

    it('notice', function()
        logger.notice('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.NOTICE, 'msg')

        assert.spy(_G.ngx.log).was.called(1)
    end)

    it('info', function()
        logger.info('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.INFO, 'msg')

        assert.spy(_G.ngx.log).was.called(1)
    end)

    it('debug', function()
        logger.debug('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.DEBUG, 'msg')

        assert.spy(_G.ngx.log).was.called(1)
    end)
end)
