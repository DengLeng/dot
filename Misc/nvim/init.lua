--- REFERENCE ---
-- https://github.com/boltlessengineer/NativeVim
-- https://github.com/HCY-ASLEEP/NVIM-Config
-- https://github.com/LazyVim/LazyVim
-- https://github.com/AstroNvim/AstroNvim
-- https://github.com/NvChad/NvChad
-- https://github.com/ayamir/nvimdots
-- https://github.com/nvim-lua/kickstart.nvim

--- OPTION ---
vim.opt.clipboard = "unnamedplus,unnamed"
vim.opt.colorcolumn = "80"
vim.opt.cursorcolumn = true
vim.opt.cursorline = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.autoindent = true
vim.opt.cindent = true
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.wildmode = "longest:full,full"
vim.opt.winminwidth = 5
vim.opt.wrap = false
vim.opt.autoread = true
vim.opt.autowrite = true
vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.writebackup = false
vim.opt.undofile = false
vim.opt.background = "dark"
vim.cmd.colorscheme("habamax")

--- KEYBINDING ---
vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.api.nvim_set_keymap("n", "<leader>CR", "<cmd>source $MYVIMRC<cr>", { desc = "Config: Reload" })
vim.api.nvim_set_keymap("n", "<leader>CE", "<cmd>edit $MYVIMRC<cr>", { desc = "Config: Edit" })
vim.api.nvim_set_keymap("i", "jk", "<esc>", { desc = "Back to Normal Mode" })
vim.api.nvim_set_keymap("v", "jk", "<esc>", { desc = "Stop Visual Mode" })
vim.api.nvim_set_keymap("c", "jk", "<c-c>", { desc = "Stop Input Commands" })
vim.api.nvim_set_keymap("i", "<C-a>", "<HOME>", { desc = "Move to Start" })
vim.api.nvim_set_keymap("v", "<C-a>", "<HOME>", { desc = "Move to Start" })
vim.api.nvim_set_keymap("c", "<C-a>", "<HOME>", { desc = "Move to Start" })
vim.api.nvim_set_keymap("i", "<C-e>", "<END>", { desc = "Move to End" })
vim.api.nvim_set_keymap("v", "<C-e>", "<END>", { desc = "Move to End" })
vim.api.nvim_set_keymap("c", "<C-e>", "<END>", { desc = "Move to End" })
vim.api.nvim_set_keymap("n", "<C-h>", "<C-w>h", { desc = "Move to Left Window" })
vim.api.nvim_set_keymap("n", "<C-j>", "<C-w>j", { desc = "Move to Down Window" })
vim.api.nvim_set_keymap("n", "<C-k>", "<C-w>k", { desc = "Move to Up Window" })
vim.api.nvim_set_keymap("n", "<C-l>", "<C-w>l", { desc = "Move to Right Window" })

--- AUTOCMD ---
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("ChangeTabSizeWithSpecificFileType", { clear = true }),
	pattern = { "python", "json", "jsonc" },
	callback = function()
		vim.bo.shiftwidth = 4
		vim.bo.tabstop = 4
		vim.bo.softtabstop = 4
	end,
})
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
	callback = function()
		vim.highlight.on_yank({ timeout = 2000 })
	end,
})
vim.api.nvim_create_autocmd("BufReadPost", {
	group = vim.api.nvim_create_augroup("LastLocation", { clear = true }),
	callback = function(event)
		local exclude = { "gitcommit" }
		local buf = event.buf
		if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
			return
		end
		vim.b[buf].lazyvim_last_loc = true
		local mark = vim.api.nvim_buf_get_mark(buf, '"')
		local lcount = vim.api.nvim_buf_line_count(buf)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("CloseWithQ", { clear = true }),
	pattern = {
		"PlenaryTestPopup",
		"checkhealth",
		"dbout",
		"gitsigns-blame",
		"grug-far",
		"help",
		"lspinfo",
		"neotest-output",
		"neotest-output-panel",
		"neotest-summary",
		"notify",
		"qf",
		"snacks_win",
		"spectre_panel",
		"startuptime",
		"tsplayground",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.schedule(function()
			vim.keymap.set("n", "q", function()
				vim.cmd("close")
				pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
			end, {
					buffer = event.buf,
					silent = true,
					desc = "Quit buffer",
				})
		end)
	end,
})
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("WrapWithSpecificType", { clear = true }),
	pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
	end,
})
vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("AutoCreateDirWhenSaveFile", { clear = true }),
	callback = function(event)
		if event.match:match("^%w%w+:[\\/][\\/]") then
			return
		end
		local file = vim.uv.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("DisabledAutoCommentNextLine", { clear = true }),
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove({ "r", "o", "c" })
	end,
})
vim.api.nvim_create_autocmd("BufWinEnter", {
	group = vim.api.nvim_create_augroup("DisableSyntaxWithLargeFile", { clear = true }),
	callback = function()
		local buf = vim.api.nvim_get_current_buf()
		local file_size = vim.fn.getfsize(vim.api.nvim_buf_get_name(buf))
		if file_size > 1.5 * 1024 * 1024 then
			vim.cmd("syntax clear")
		end
	end,
})

--- LAZY.NVIM ---
if not vim.loop.fs_stat(vim.fn.stdpath("data") .. "/lazy/lazy.nvim") then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		vim.fn.stdpath("data") .. "/lazy/lazy.nvim",
	})
end
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/lazy.nvim")
require("lazy").setup({
	default = {
		lazy = true,
		version = "*",
		cond = nil,
	},
	ui = {
		size = {
			width = 0.92,
			height = 0.92,
		},
		wrap = true,
		border = "rounded",
		title = "lazy.nvim Panel",
		title_pos = "center",
		backdrop = 100,
	},
	performance = {
		rtp = {
			disabled_plugins = {
				"editorconfig",
				"2html_plugin",
				"tohtml",
				"getscript",
				"getscriptPlugin",
				"gzip",
				"logipat",
				"netrw",
				"netrwPlugin",
				"netrwSettings",
				"netrwFileHandlers",
				"man",
				"matchit",
				"matchparen",
				"osc52",
				"tar",
				"tarPlugin",
				"rplugin",
				"rrhelper",
				"shada",
				"spellfile",
				"spellfile_plugin",
				"vimball",
				"vimballPlugin",
				"zip",
				"zipPlugin",
				"tutor",
				"rplugin",
				"syntax",
				"synmenu",
				"optwin",
				"compiler",
				"bugreport",
				"ftplugin",
			},
		},
	},
	spec = {
		-- LazyVim --
		-- {
		-- 	"LazyVim/LazyVim",
		-- 	import = "lazyvim.plugins",
		-- },
		-- AstroNvim --
		{
			"AstroNvim/AstroNvim",
			version = "^4",
			import = "astronvim.plugins",
		},
		{
			"AstroNvim/astrocommunity",
			import = "astrocommunity.pack.lua",
		},
	},
	local_spec = true,
	profiling = {
		loader = true,
		require = true,
	},
})
