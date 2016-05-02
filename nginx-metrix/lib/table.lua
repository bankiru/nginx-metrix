if _G['ordered_pairs'] == nil then
    local ordered_next = function (t, state)
        local __gen_ordered_index = function ( t )
            local ordered_index = {}
            for key in pairs(t) do
                table.insert( ordered_index, key )
            end
            table.sort(ordered_index)
            return ordered_index
        end

        -- Equivalent of the next function, but returns the keys in the alphabetic
        -- order. We use a temporary ordered key table that is stored in the
        -- table being iterated.

        local key
        if state == nil then
            -- the first time, generate the index
            t.__ordered_index = __gen_ordered_index( t )
            key = t.__ordered_index[1]
        else
            -- fetch the next value
            for i = 1,#t.__ordered_index do
                if t.__ordered_index[i] == state then
                    key = t.__ordered_index[i+1]
                end
            end
        end

        if key then
            return key, t[key]
        end

        -- no more value to return, cleanup
        t.__ordered_index = nil
        return
    end

    local ordered_pairs = function(t)
        return ordered_next, t, nil
    end

    _G['ordered_next'] = ordered_next
    _G['ordered_pairs'] = ordered_pairs
end
