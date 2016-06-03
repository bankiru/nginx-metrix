--known statuses:
--    100, 101, 102,
--    200, 201, 202, 203, 204, 205, 206, 207, 208, 226,
--    300, 301, 302, 303, 304, 305, 307, 308,
--    400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 421, 422, 423, 424,
--    426, 428, 429, 431, 451, 499,
--    500, 501, 502, 503, 504, 505, 506, 507, 508, 510, 511, 599,

local field_params = { format = '%d', cyclic = true, }

local collector = {
  name = 'status',
  fields = {
    ['200'] = field_params,
    ['301'] = field_params,
    ['302'] = field_params,
    ['304'] = field_params,
    ['403'] = field_params,
    ['404'] = field_params,
    ['500'] = field_params,
    ['502'] = field_params,
    ['503'] = field_params,
    ['504'] = field_params,
  },
  ngx_phases = { [[log]] },
  on_phase = function(self, phase)
    if phase == 'log' and ngx.status ~= nil then
      if self.fields[tostring(ngx.status)] == nil then
        self.fields[tostring(ngx.status)] = field_params
      end
      self.storage:cyclic_incr(ngx.status)
    end
  end,
}

return collector
