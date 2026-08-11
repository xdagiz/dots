local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local rep = require("luasnip.extras").rep

return {
	s({ trig = "wrap", wordTrig = true }, {
		t("<"),
		i(1, "div"),
		t(">"),
		f(function(_, parent)
			local sel = parent.snippet.env.TM_SELECTED_TEXT
			if sel and #sel > 0 then
				return sel
			end
			return {}
		end, {}),
		t("</"),
		rep(1),
		t(">"),
	}),
}
