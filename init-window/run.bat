
@echo off
echo Building Odin project...
odin build src -target:orca_wasm32 -out:module.wasm

echo Bundling with Orca...
orca bundle --name output --resource-dir data module.wasm
output\bin\output.exe
