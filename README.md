# LSP Definition Generator in Lua

This project is used to generate type definitions for the Language Server
Protocol (LSP), parsable by
[LuaLS/lua-language-server](https://github.com/LuaLS/lua-language-server).
All LSP definitions are namespaced under `lsp`.

All definitions for [goldenstein64/lua-lsp-lib](https://github.com/goldenstein64/lua-lsp-lib), my work-in-progress LSP library, are namespaced under `lsp*`.

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

This project writes an `out/` directory with the following contents:

The `enum/` directory contains all LSP enum definitions, written as Lua tables where keys are enum names and values are enum values. `lua-lsp-lib` already comes packaged with these in `lsp-lib.enum.*`. e.g. the `lsp-lib.enum.ErrorCodes` module points to the `ErrorCodes` LSP enum.

The `routes/` directory contains all LSP route definitions that implement server-to-client communications, like `initialize` or `workspace/diagnostic`. They are all typed for LuaLS according to `lsp.d.lua`. The intended usage is to have a sort of registry that assigns all these files' returned functions to `lsp-lib.response`, like so:

```lua
local response = require("lsp-lib.response")

local function impl(method)
	response[method] = require("routes." .. method:gsub("/", "."))
end

impl "initialize"
impl "shutdown"

impl "workspace/diagnostic"

-- ...
```

All routes can go in an `unusedRoutes/` directory, and as they're implemented, they can go to an active `routes/` directory.

`lsp.d.lua` is a file containing type definitions for everything in the LSP specification that isn't an enumeration. That includes everything from requests/responses/notifications to client/server capabilities to `LSPAny` and everything in between. As a result, it's an exceptionally large file.

`lsp-lib.d.lua` is a file containing type definitions for the `lua-lsp-lib` library, specifically `lsp-lib.response`, `lsp-lib.request`, and `lsp-lib.notify`. This is for generating the typed indexing API and providing typed route definitions when indexing `lsp-lib.response` directly.
