# LSP Definition Generator in Lua

This project is used to generate type definitions for the Language Server
Protocol (LSP), parsable by
[LuaLS/lua-language-server](https://github.com/LuaLS/lua-language-server).
All LSP definitions are namespaced under `lsp`. All definitions for
implementing my work-in-progress LSP library are namespaced under `lsp*`.

This project is under MIT, so you can fork it for other kinds of type
definitions.

## Usage

This project reads and writes to the file system, so it's recommended
to use this project in a new directory.

```sh
$ luarocks init --version=5.1
$ luarocks install lsp-def-gen
$ mkdir data
$ curl https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/metaModel/metaModel.json -o data/metaModel.json
$ lua -e "require('lsp-def-gen.main')" # -> files generated in ./out
```

Any `metaModel.json` file will work as long as it follows the
`metaModel.schema.json` file from version 3.17.
