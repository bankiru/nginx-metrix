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
        assert.spy(_G.ngx.log).was.called_with(ngx.INFO, '[metrix] msg')

        logger.log(ngx.INFO, { msg = 'msg' })
        assert.spy(_G.ngx.log).was.called_with(ngx.INFO, "[metrix] {\n  msg = \"msg\"\n}")

        logger.log(ngx.INFO, 'msg', 'another arg')
        assert.spy(_G.ngx.log).was.called_with(ngx.INFO, '[metrix] msg :: { "another arg" }')

        assert.spy(_G.ngx.log).was.called(3)
    end)

    it('stderr', function()
        logger.stderr('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.STDERR, '[metrix] msg')

        logger.stderror('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.STDERR, '[metrix] msg')

        assert.spy(_G.ngx.log).was.called(2)
    end)

    it('emerg', function()
        logger.emerg('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.EMERG, '[metrix] msg')

        logger.emergency('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.EMERG, '[metrix] msg')

        assert.spy(_G.ngx.log).was.called(2)
    end)

    it('alert', function()
        logger.alert('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.ALERT, '[metrix] msg')

        assert.spy(_G.ngx.log).was.called(1)
    end)

    it('crit', function()
        logger.crit('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.CRIT, '[metrix] msg')

        logger.critical('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.CRIT, '[metrix] msg')

        assert.spy(_G.ngx.log).was.called(2)
    end)

    it('err', function()
        logger.err('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.ERR, '[metrix] msg')

        logger.error('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.ERR, '[metrix] msg')

        assert.spy(_G.ngx.log).was.called(2)
    end)

    it('warn', function()
        logger.warn('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.WARN, '[metrix] msg')

        logger.warning('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.WARN, '[metrix] msg')

        assert.spy(_G.ngx.log).was.called(2)
    end)

    it('notice', function()
        logger.notice('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.NOTICE, '[metrix] msg')

        assert.spy(_G.ngx.log).was.called(1)
    end)

    it('info', function()
        logger.info('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.INFO, '[metrix] msg')

        assert.spy(_G.ngx.log).was.called(1)
    end)

    it('debug', function()
        logger.debug('msg')
        assert.spy(_G.ngx.log).was.called_with(ngx.DEBUG, '[metrix] msg')

        assert.spy(_G.ngx.log).was.called(1)
    end)
end)
