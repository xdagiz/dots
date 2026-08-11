return {
  "snacks.nvim",
  ---@module 'snacks'
  ---@type snacks.Config
  opts = {
    picker = {
      sources = {
        explorer = {
          layout = {
            layout = {
              width = 32,
            },
          },
        },
      },
    },
    scroll = { enabled = false },
    bigfile = { enabled = true },
    dashboard = {
      enabled = false,
      preset = {
        pick = nil,
        header = [[
██╗  ██╗██████╗  █████╗  ██████╗ ██╗███████╗
╚██╗██╔╝██╔══██╗██╔══██╗██╔════╝ ██║╚══███╔╝
 ╚███╔╝ ██║  ██║███████║██║  ███╗██║  ███╔╝ 
 ██╔██╗ ██║  ██║██╔══██║██║   ██║██║ ███╔╝  
██╔╝ ██╗██████╔╝██║  ██║╚██████╔╝██║███████╗
╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝╚══════╝
        ]],
      },
    },
    zen = {
      toggles = {
        -- dim = false,
      },
    },
  },
}
