local collector = {
  name = 'request',
  ngx_phases = { [[log]] },
  fields = {
    rps = { format = '%d', cyclic = true, },
    internal_rps = { format = '%d', cyclic = true, },
    https_rps = { format = '%d', cyclic = true, },
    time_ps = { format = '%0.3f', mean = true, },
    length_ps = { format = '%0.3f', mean = true, },
  }
}

function collector:on_phase(phase)
  if phase == 'log' then
    self.storage:cyclic_incr('rps')
    self.storage:mean_add('time_ps', ngx.var.request_time)
    if ngx.req.is_internal() then self.storage:cyclic_incr('internal_rps') end
    if ngx.var.https == 'on' then self.storage:cyclic_incr('https_rps') end
    if ngx.var.request_length ~= nil and tonumber(ngx.var.request_length) > 0 then self.storage:mean_add('length_ps', ngx.var.request_length) end
  end
end

return collector
