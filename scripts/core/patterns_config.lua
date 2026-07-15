return {
  cell_size = 16, -- The map will be virtually divided into cells of the given size: for each layer and cell only one pattern can exist (the topmost one).
  tags = {
    debug = {
      ["8"] = "diggable",
    }, -- Tags for patterns of the "debug" tileset (used by me).
  }, -- Pattern tags, organized by tileset and pattern.
}