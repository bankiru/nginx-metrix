local logger = require 'nginx-metrix.logger'

local collectors = {}

---
-- @param collector table
--
local attach_collector = function(collector)
    if is.callable(collector.periodically) then
        table.insert(collectors, collector)
    end
end

local delay = 1
local handler
handler = function (premature, collectors)
    if premature then
        return
    end

    collectors:map(
        function(collector)
            return collector, ngx.thread.spawn(function() collector:periodically() end)
        end
    ):each(
        function(collector, thread)
            local ok, res = ngx.thread.wait(thread)
            if not ok then
                logger.error(("failed to run Collector<%s>:periodically(): %s"):format(collector.name, res))
            end
        end
    )

    local ok, err = ngx.timer.at(delay, handler, collectors)
    if not ok then
        logger.error("Failed to continue the scheduler - failed to create the timer: ", err)
        return
    end
end

---
--
local start = function()
    local ok, err = ngx.timer.at(delay, handler, iter(collectors))
    if not ok then
        logger.error("Failed to start the scheduler - failed to create the timer: ", err)
        return
    end
end

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------
local exports = {}
exports.attach_collector = attach_collector
exports.start = start

if __TEST__ then
    exports.__private__ = {
        get_collectors = function() return collectors end,
        handler = handler,
    }
end

return exports