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
   "lua >= 5.1",
   "luafilesystem ~> 1.8",
   "dkjson ~> 2.6"
}
build = {
   type = "builtin",
   modules = {
      ["lsp-def-gen.init"] = "lsp-def-gen/init.lua",

      ["lsp-def-gen.compile.init"] = "lsp-def-gen/compile/init.lua",
      ["lsp-def-gen.compile.Enumeration"] = "lsp-def-gen/compile/Enumeration.lua",
      ["lsp-def-gen.compile.MetaModel"] = "lsp-def-gen/compile/MetaModel.lua",
      ["lsp-def-gen.compile.Notification"] = "lsp-def-gen/compile/Notification.lua",
      ["lsp-def-gen.compile.Property"] = "lsp-def-gen/compile/Property.lua",
      ["lsp-def-gen.compile.Request"] = "lsp-def-gen/compile/Request.lua",
      ["lsp-def-gen.compile.Structure"] = "lsp-def-gen/compile/Structure.lua",
      ["lsp-def-gen.compile.StructureLiteral"] = "lsp-def-gen/compile/StructureLiteral.lua",
      ["lsp-def-gen.compile.Type"] = "lsp-def-gen/compile/Type.lua",
      ["lsp-def-gen.compile.TypeAlias"] = "lsp-def-gen/compile/TypeAlias.lua",

      ["lsp-def-gen.compile.util.Buffer"] = "lsp-def-gen/compile/util/Buffer.lua",
      ["lsp-def-gen.compile.util.move"] = "lsp-def-gen/compile/util/move.lua",
      ["lsp-def-gen.compile.util.maybeMove"] = "lsp-def-gen/compile/util/maybeMove.lua",
   },
}
