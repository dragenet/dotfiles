return {
	"lemarsu/sops.nvim",
	opts = function()
		local config = require("sops.config")
		config.follow = { "XDG_CONFIG_HOME" }
	end,
}
