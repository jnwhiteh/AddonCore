# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AddonCore is a slim embedded library for World of Warcraft addon development. It provides event registration, module support, deferred execution, and localization scaffolding. This is designed to be embedded directly into WoW addons (not installed as a standalone dependency).

## Development Environment

**No build/test/lint commands** - This is a Lua library loaded directly by WoW. Testing happens in-game.

**LSP warnings for WoW globals are expected** - Functions like `CreateFrame`, `GetBuildInfo`, `UIParent`, etc. are WoW API globals. The Lua language server doesn't know about them unless configured with WoW API type definitions.

## Architecture

The library creates an addon object passed via varargs (`local addon = select(2, ...)`), registers it globally (`_G[addonName] = addon`), then mixes in functionality via two patterns:

**Mixins** (mixed into addon and modules):
- `EventedMixin`: Multi-handler event registration with `RegisterEvent`/`UnregisterEvent`
- `MessagedMixin`: Internal pub/sub via `RegisterMessage`/`UnregisterMessage`/`FireMessage`

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
