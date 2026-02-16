# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AddonCore is a slim embedded library for World of Warcraft addon development. It provides event registration, module support, deferred execution, and localization scaffolding. This is designed to be embedded directly into WoW addons (not installed as a standalone dependency).

## Development Environment

**Run tests**: `lua tests/run.lua` from the project root. The test harness mocks WoW API globals, allowing command-line testing of core functionality.

**LSP warnings for WoW globals are expected** - Functions like `CreateFrame`, `GetBuildInfo`, `UIParent`, etc. are WoW API globals. The Lua language server doesn't know about them unless configured with WoW API type definitions. Similarly, LSP warnings about `xpcall` argument counts are expected (WoW's xpcall signature differs from standard Lua 5.1).

## Architecture

The library creates an addon object passed via varargs (`local addon = select(2, ...)`), registers it globally (`_G[addonName] = addon`), then mixes in functionality via two patterns:

**Mixins** (mixed into addon and modules):
- `EventedMixin`: Multi-handler event registration with `RegisterEvent`/`RegisterUnitEvent`/`UnregisterEvent`
- `MessagedMixin`: Internal pub/sub via `RegisterMessage`/`UnregisterMessage`/`FireMessage`

**Unit events**: `RegisterUnitEvent` filters dispatch by unit - handlers only fire when the incoming unit matches one they registered for. Units are stored as dictionary tables for O(1) lookup. Cannot mix unit and non-unit handlers for the same event.

**Lifecycle hooks** (called automatically):
- `Initialize`: Called on `ADDON_LOADED` when saved variables are ready
- `Enable`: Called on `PLAYER_LOGIN` when UI is ready

The internal event handling for Initialize and Enable happen on an internal frame that is separate and isolated from the main addon event system, to prevent pollution and potential issues.

Modules registered via `addon:RegisterModule(module, name)` receive these same mixins and lifecycle callbacks. Late-registered modules get their callbacks invoked immediately if the lifecycle already passed.

**Combat deferral**: `addon:Defer(fn)` queues execution until combat ends (`PLAYER_REGEN_ENABLED`), or runs immediately if not in combat.

## Handler Patterns

Event/message handlers accept either:
- A function: `addon:RegisterEvent("EVENT", function(event, ...) end)`
- A method name string: `addon:RegisterEvent("EVENT", "OnEvent")` - calls `self:OnEvent(event, ...)`
