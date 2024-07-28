return {
    "gbprod/nord.nvim",
    lazy = false,
    config = function()
        require("nord").setup({
            transparent = true,
            errors = { mode = "bg" }
        })
        -- vim.cmd.colorscheme("nord")
    end,
};
