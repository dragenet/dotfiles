return {
  "kylechui/nvim-surround",
  version = "^4.0.0",
  event = "VeryLazy",
  -- Default setup is solid — no need to override anything
  -- Key operations to internalize:
  --   ys{motion}{char}  add surround  e.g. ysiw" wraps word in quotes
  --   cs{from}{to}      change surround  e.g. cs'" changes ' to "
  --   ds{char}          delete surround  e.g. ds" removes surrounding quotes
  --   dst               delete surrounding HTML tag
  --   S{char} (Visual)  surround selection
  --
  -- Tip: open delimiter adds spaces ( hello ), close delimiter doesn't (hello)
  --   ysiw(  →  ( hello )
  --   ysiw)  →  (hello)
  opts = {},
}
