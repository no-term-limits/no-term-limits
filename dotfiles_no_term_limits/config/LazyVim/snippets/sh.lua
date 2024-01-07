return {
	s(
		"h",
		f(function(_, snip)
			-- return vim.fn.trim(vim.fn.system("bash_script_header"))
			local output = vim.fn.systemlist("bash_script_header")
			local trimmed_output = {}
			for _, line in ipairs(output) do
				table.insert(trimmed_output, line)
			end
			return trimmed_output
		end, {})
	),
}
