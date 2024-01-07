return {
	s("he", t("also loaded!!")),
	s("help", t("also loaded help!!")),
	s(
		"ha",
		f(function(args, snip, user_arg_1)
			return vim.fn.trim(vim.fn.system([['date -d ']] .. target_date .. [[' +'%F %a']]))
		end, {})
	),
}
