#!/usr/bin/env bash

source "$(dirname "$0")/test_lib.sh"

temp_home=$(create_isolated_nvim_home)

cleanup() {
  rm -rf "$temp_home"
}
trap cleanup EXIT

output=$(run_headless_nvim "$temp_home" +'lua local cmp=require("blink.cmp"); local cfg=require("blink.cmp.config"); local sources=require("blink.cmp.sources.lib"); print("HAS_LSP_CAPS=" .. tostring(type(cmp.get_lsp_capabilities) == "function")); print("DEFAULT=" .. table.concat(cfg.sources.default, ",")); print("ENABLED=" .. table.concat(sources.get_enabled_provider_ids("default"), ","))' +"qall!")

assert_contains "$output" "HAS_LSP_CAPS=true"
assert_contains "$output" "DEFAULT=snippets,lsp,path,buffer"
assert_contains "$output" "ENABLED=snippets,lsp,path,buffer"
