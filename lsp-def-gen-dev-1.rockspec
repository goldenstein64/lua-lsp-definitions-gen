package = "lsp-def-gen"
version = "dev-1"
source = {
   url = "git+https://github.com/goldenstein64/lsp-definitions-gen.git",
   dir = "lsp-def-gen"
}
description = {
   homepage = "https://github.com/goldenstein64/lsp-definitions-gen",
   license = "MIT"
}
dependencies = {
   "lua ~> 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["lsp_def_gen.init"] = "src/init.lua",

      ["lsp_def_gen.compile.init"] = "src/compile/init.lua",
      ["lsp_def_gen.compile.Enumeration"] = "src/compile/Enumeration.lua",
      ["lsp_def_gen.compile.MetaModel"] = "src/compile/MetaModel.lua",
      ["lsp_def_gen.compile.Notification"] = "src/compile/Notification.lua",
      ["lsp_def_gen.compile.Property"] = "src/compile/Property.lua",
      ["lsp_def_gen.compile.Request"] = "src/compile/Request.lua",
      ["lsp_def_gen.compile.Structure"] = "src/compile/Structure.lua",
      ["lsp_def_gen.compile.StructureLiteral"] = "src/compile/StructureLiteral.lua",
      ["lsp_def_gen.compile.Type"] = "src/compile/Type.lua",
      ["lsp_def_gen.compile.TypeAlias"] = "src/compile/TypeAlias.lua",

      ["lsp_def_gen.compile.util.Buffer"] = "src/compile/util/Buffer.lua",
      ["lsp_def_gen.compile.util.move"] = "src/compile/util/move.lua",
      ["lsp_def_gen.compile.util.maybeMove"] = "src/compile/util/maybeMove.lua",
   },
}
