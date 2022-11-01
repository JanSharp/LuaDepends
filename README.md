
# Why

Have you ever found yourself splitting up logic into 2 files but then a few parts of the 2 files have to interact with the other file which would require you to `require` both files back and forth, which is an infinite loop?

Have you then tried to split the files again, adding a 3rd file which is supposed to have the cross interacting logic in it, but realized that it won't work or is tedious and not at all clean?

Have you then considered using globals so you can avoid the calls to `require` back and forth entirely and only `require` the 2 files from the main entry point, such that all the cross interacting logic just uses globals, but the more you thought about it you decided against it because you didn't want to plat a time bomb in your code that would get you lost trying to keep track of the definition and usage of globals?

Have then thought about merging the 2 files back into 1, but were really annoyed by that idea?

Well at that point you're pretty much stuck with picking the lesser evil.

However using `depends` you might be able to have a clean solution. It does however apply a few rules on both the requiring and the required side.

# Requirements

The `depends.lua` module **must be the first module that is `require`ed** (because it replaces `require`).

Restrictions on the file that `depends` on another file:
- It must not use the other file until said other file is done loading, which is usually once the main chunk is finished.
- It must never modify the return value of `depends`, only tables inside of the return value are mutable.

Restrictions on the file being `depend`ed upon:
- It must return a table containing immutable data. Nested tables/data inside of that table are mutable.
- It must only return one value. (Let's be honest, no file should ever return > 1 value anyway considering how `require` works.)

# How it works

It's best explained by going through the steps `depends.lua` goes through when requiring or depending on a file.

- If the required file was already loaded previously, then return the cached result (just like `require`).
- If the required file is currently in the process of loading:
  - If `require` was used it's an error.
  - If `depends` was used it returns a placeholder table with a metatable to prevent indexing and assigning.
- Actually load the required file and cache the result.
- If there were attempts at loading this file while it was loading:
  - Go through all placeholder tables:
    - Remove the dummy metatable.
    - Copy all fields from the actual result to the placeholder.
    - set the metatalbe of the now populated placeholder equal to the actual result's metatable.
- Return the result.

# Suggested usage

First of all, the default annotations for `depends` and `require` are for [sumneko.lua](https://github.com/sumneko/lua-language-server)'s EmmyLua. As such, my suggestions are also using the same annotations.

In order to get intellisense for the return value of a `depends` call, make a class that matches the string passed to `depends`. I like to do it like this for a file that is required using `depends("my_folder.my_module")`, but you can choose a different approach:

```lua
local function foo() end
local function bar() end
---@class my_folder.my_module
return {
  foo = foo,
  bar = bar,
}
```

It seems even though `depends.lua` is overwriting `require`, sumneko.lua still uses the same type inference as it would for the regular old `require`, so if some file is only ever required using `require` - and never `depends` - then the class for the return value is not necessary.

In Factorio I actually just ended up using `---@class __mod-name__.my_folder.my_module` and used fully qualified requires everywhere, even inside of the same mod.

Outside of Factorio I would suggest the same - using fully qualified names for all modules, so you never have to think about what name to use when requiring a file or what class name to use when writing a file.

# Simple setup

By following this scheme for a project you'd hardly have to think about when to use `require` vs `depends`, vice versa.

- Have the main entry point(s) always use `require` to require other files.
- Have "util" files (usually just one, potentially multiple in big projects):
  - Util files only contain very generic helper functions and they themselves do not require any other files, except _maybe_ some other util files.
  - Util files should always be required using `require`, that way the generic helper functions are available in the main chunk of other files, or simply put "available everywhere".
- Have all other files be modules serving some more specific purpose.
  - Their return value matches the requirements for `depends`. Easiest way to do that is to only put functions in the result table, and if other data must be exposed it is put inside a nested table inside of the result table.
  - Always use `depends` to require modules in other modules.

You don't have to follow this to the letter, but it should give you a good idea for how you can use `depends.lua` in a project.
