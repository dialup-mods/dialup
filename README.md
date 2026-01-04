<h1 align="center">🌐 Welcome to the Dial-Up Framework 🌐</h1>
<p align="center">*Best viewed in 800x600*</p>

This is the main source code repository for the Dial-Up Framework, a next-generation modding framework for Unreal Engine. It contains the core framework, injection module, SDK generator, SDK plugin creator, DLL injector, example plugins, and documentation.

> ⚠️ **PRERELEASE** - SDK tooling is production-ready. Framework components coming soon.

## Available Now

### [SDK Generator](https://github.com/dialup-mods/sdk-generator)
Generate clean, type-safe SDKs for Unreal Engine 3 games. Fixes 11-year-old bugs, zero warnings, proper type reflection, and proper inheritance--no more fake script glue classes! Simple to configure with a single source of truth.

**We questioned the pattern. You should too.**

**Status:** Released. Docs in progress.

### [SDK Plugin](https://github.com/dialup-mods/sdk-plugin)
Build your generated SDK into a reusable static library for multiple- and cross-plugin use.

No more polluted global namespace.

**Status:** Released. Docs in progress.

### [Injector](https://github.com/dialup-mods/injector)
A simple DLL injector for use in the build system. It's as easy as `make inject`

**Status:** Released. Docs in progress.

## 🚧 Under Construction 🚧

### [Core](https://github.com/dialup-mods/framework)
High-performance plugin orchestrator with an advanced (yet easy to use!) dependency injection system and hot-reload support. A FREE ModuleBuilder and Resolver come with every plugin; we handle the hard stuff so you can focus your time on writing plugins instead of worrying about lifecycle.

**Status:** Core functionality complete. Source is released, but depends on AIM for engine interaction. Docs in progress.

### [AIM](https://github.com/dialup-mods/aim) (Advanced Injection Module)
Detour plugin with expressive tasks (hooks) scripting. Double-buffered tasks queue, error handling in the hot path, sub 1ms overhead. It's actually cracked.

**Status:** Headers available for study. Security hardening in progress. Docs in progress.

### [Plugins](https://github.com/dialup-mods/plugins)
We have some. We think you'll like them. Plan on seeing some of the smaller examples soon, with the more complex plugins shipping around the same time as AIM.

---

## Quick Start

See individual repository READMEs for installation and usage.

Full documentation: https://docs.dialup.now (coming soon)

## Philosophy

Built to production standards. Clean architecture, zero warnings, actually maintainable code.

*For professional inquiries: aol@chasondeshotel.com*
