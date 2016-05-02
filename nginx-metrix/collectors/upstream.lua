local collector = {
    name = 'upstream',
    ngx_phases = { [[log]] },
    fields = {
        count = { format = '%d', },
        connect_time = { format = '%0.3f', },
        header_time = { format = '%0.3f', },
        response_time = { format = '%0.3f', },
    }
}

function collector:on_phase(phase)
    if phase == 'log' and ngx.var.upstream_addr ~= nil then
        self.storage:safe_incr('count')
        self.storage:safe_incr('connect_time', ngx.var.upstream_connect_time)
        self.storage:safe_incr('header_time', ngx.var.upstream_header_time)
        self.storage:safe_incr('response_time', ngx.var.upstream_response_time)
    end
end

return collector
