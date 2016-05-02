local collector = {
    name = 'request',
    ngx_phases = { [[log]] },
    fields = {
        count = { format = '%d', },
        total_time = { format = '%0.3f', },
        internal_count = { format = '%d', },
        https_count = { format = '%d', },
        total_length = { format = '%d', },
    }
}

function collector:handle_ngx_phase(phase)
    if phase == 'log' then
        self.storage:incr_safe('count')
        self.storage:incr_safe('total_time', ngx.var.request_time)
        if ngx.req.is_internal() then self.storage:incr_safe('internal_count') end
        if ngx.var.https == 'on' then self.storage:incr_safe('https_count') end
        if ngx.var.request_length ~= nil and tonumber(ngx.var.request_length) > 0 then self.storage:incr_safe('total_length', ngx.var.request_length) end
    end
end

return collector
