return {
    {
        "gbprod/nord.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("nord").setup({
                transparent = true,
                errors = { mode = "bg" }
            })
            -- vim.cmd.colorscheme("nord")
        end,
    },
};
