--known statuses:
--    100, 101, 102,
--    200, 201, 202, 203, 204, 205, 206, 207, 208, 226,
--    300, 301, 302, 303, 304, 305, 307, 308,
--    400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 421, 422, 423, 424,
--    426, 428, 429, 431, 451, 499,
--    500, 501, 502, 503, 504, 505, 506, 507, 508, 510, 511, 599,

local collector = {
    name = 'status',
    fields = {
        ['200'] = {},
        ['301'] = {},
        ['302'] = {},
        ['304'] = {},
        ['403'] = {},
        ['404'] = {},
        ['500'] = {},
        ['502'] = {},
        ['503'] = {},
        ['504'] = {},
    },
    ngx_phases = {[[log]]},
    on_phase = function(self, phase)
        if phase == 'log' and ngx.status ~= nil then
            if self.fields[tostring(ngx.status)] == nil then
                self.fields[tostring(ngx.status)] = {}
            end
            self.storage:safe_incr(ngx.status)
        end
    end,
}

return collector
