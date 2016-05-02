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

function collector:handle_ngx_phase(phase)
    if phase == 'log' and ngx.var.upstream_addr ~= nil then
        self.storage:incr_safe('count')
        self.storage:incr_safe('connect_time', ngx.var.upstream_connect_time)
        self.storage:incr_safe('header_time', ngx.var.upstream_header_time)
        self.storage:incr_safe('response_time', ngx.var.upstream_response_time)
    end
end

return collector
