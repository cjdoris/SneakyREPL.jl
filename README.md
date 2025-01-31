# SneakyREPL.jl

A Julia package that can make your REPL look like Python's, IPython's, or R's REPL.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/cjdoris/SneakyREPL.jl")
```

## Usage

```julia
using SneakyREPL

# Enable Python mode
SneakyREPL.enable("python")

# Enable IPython mode
SneakyREPL.enable("ipython")

# Enable R mode
SneakyREPL.enable("r")

# Switch back to Julia mode
SneakyREPL.enable("julia")

# Use preferred mode from preferences (defaults to "julia")
SneakyREPL.enable()
```

When Python mode is enabled:
- The REPL prompt changes to Python's `>>>` style
- The REPL banner is changed to look like Python's banner

When IPython mode is enabled:
- The REPL prompt changes to IPython's `In [n]:` style with automatic numbering
- Output is prefixed with `Out [n]:` matching the input number
- The REPL banner is changed to look like IPython's banner

When R mode is enabled:
- The REPL prompt changes to R's `>` style
- Output is prefixed with `[1]` in R's style
- The REPL banner is changed to look like R's banner

You can set your preferred mode in your Julia startup file (`~/.julia/config/startup.jl`):
```julia
using Preferences
@set_preferences!("mode" => "python")  # or "julia", "ipython", or "r"
```
