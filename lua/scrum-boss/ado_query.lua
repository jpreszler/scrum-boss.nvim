local n = require("nui-components")
 
local renderer = n.create_renderer({
  width = 60,
  height = 12,
})
 
local signal = n.create_signal({
  query = "",
  are_results_visible = false,
})

local buf = vim.api.nvim_create_buf(false, true)
 
local body = function()
  return n.rows(
    n.text_input({
        autofocus = true,
        border_label = "Query",
        on_change = function(value)
            signal.query = value
        end,
    }),
    n.buffer({
        id = "results",
        flex=1,
        buf=buf,
        autoscroll = false,
        border_label = "Results",
        hidden = signal.are_results_visible:negate(),
    })
  )
end

renderer:add_mappings({
    {
        mode = {"n", "i"},
        key = "<S-CR>",
        handler = function()
            local state = signal:get_value()
            renderer:set_size({height = 20})
            signal.are_results_visible = true
            renderer:schedule(function()
                local full_query = "az boards query --wiql '"..state.query.."' --output table"
                local conn = assert(io.popen(full_query, 'r'))
                local results = assert(conn:read('*a'))
                conn:close()
                for line in results:gmatch('[^\n]+') do
                    vim.api.nvim_buf_set_lines(buf, -1, -1, true, {line})
                end
            end)
        end,
    }
})

renderer:render(body)
