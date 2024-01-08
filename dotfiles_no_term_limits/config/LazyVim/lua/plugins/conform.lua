return {
	"stevearc/conform.nvim",
	opts = {
		formatters = {
			-- use extra args with shfmt. -i 2 says use two spaces. otherwise it uses tabs
			shfmt = {
				prepend_args = { "-i", "2" },
			},
		},
	},
}
