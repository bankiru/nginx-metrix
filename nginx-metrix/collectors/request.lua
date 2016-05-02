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

function collector:on_phase(phase)
    if phase == 'log' then
        self.storage:safe_incr('count')
        self.storage:safe_incr('total_time', ngx.var.request_time)
        if ngx.req.is_internal() then self.storage:safe_incr('internal_count') end
        if ngx.var.https == 'on' then self.storage:safe_incr('https_count') end
        if ngx.var.request_length ~= nil and tonumber(ngx.var.request_length) > 0 then self.storage:safe_incr('total_length', ngx.var.request_length) end
    end
end

return collector
