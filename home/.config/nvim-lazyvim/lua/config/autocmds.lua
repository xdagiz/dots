-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function biome_fix_all(client, bufnr)
  if client.name ~= "biome" then
    return
  end

  local ft = vim.bo[bufnr].filetype or ""
  if not (ft:match("^javascript") or ft:match("^typescript")) then
    return
  end

  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = bufnr,
    group = vim.api.nvim_create_augroup("BiomeFixAll_" .. bufnr, { clear = true }),
    callback = function(ev)
      local ok, err = pcall(function()
        local end_line = vim.api.nvim_buf_line_count(bufnr) - 1
        local last_line_content = vim.api.nvim_buf_get_lines(bufnr, end_line, end_line + 1, true)[1] or ""
        local end_char = #last_line_content

        local res = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", {
          textDocument = vim.lsp.util.make_text_document_params(bufnr),
          range = {
            start = { line = 0, character = 0 },
            ["end"] = { line = end_line, character = end_char },
          },
          context = {
            only = { "source.fixAll.biome", "source.organizeImports.biome" },
            diagnostics = {},
          },
        }, 1000)
        if res then
          for client_id, resp in pairs(res) do
            if resp.result then
              for _, action in ipairs(resp.result) do
                -- Apply workspace edit if present
                if action.edit then
                  vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
                end
                -- Execute command if any
                if action.command then
                  vim.lsp.buf.execute_command(action.command)
                end
              end
            end
          end
        end
      end)
      if not ok then
        vim.notify("Biome fixAll failed: " .. tostring(err), vim.log.levels.WARN)
      end
    end,
  })
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end
    biome_fix_all(client, args.buf)
  end,
})

vim.cmd("silent! Copilot disable")
