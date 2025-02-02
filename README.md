# SneakyREPL.jl

A Julia package that can make your REPL look like Python's, IPython's, R's, or Mojo's REPL.

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

# Enable Mojo mode
SneakyREPL.enable("mojo")

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

When Mojo mode is enabled:
- The REPL prompt changes to Mojo's `n>` style with automatic numbering
- The REPL banner is changed to look like Mojo's banner with emoji

You can set your preferred mode in your Julia startup file (`~/.julia/config/startup.jl`):
```julia
using Preferences
@set_preferences!("mode" => "python")  # or "julia", "ipython", "r", or "mojo"
```

## Preferences

You can customize various aspects of SneakyREPL using Julia's preferences system. The recommended way is to use [PreferenceTools.jl](https://github.com/cjdoris/PreferenceTools.jl) for a more user-friendly experience. Press `]` to enter the Pkg mode and then:

```julia-repl
pkg> add PreferenceTools SneakyREPL

julia> using PreferenceTools

pkg> preference add SneakyREPL mode=python  # or "julia", "ipython", "r", or "mojo"

pkg> preference add SneakyREPL python_version=3.13.1
```

Alternatively, you can use Preferences.jl directly.

The following placeholders are available in banner templates:
- `{JULIA_VERSION}`: Current Julia version
- `{MACHINE}`: System architecture
- `{WORD_SIZE}`: System word size (32/64-bit)
- `{PYTHON_VERSION}`: Python version (from preference or default)
- `{IPYTHON_VERSION}`: IPython version (from preference or default)
- `{R_VERSION}`: R version (from preference or default)
- `{R_VERSION_NAME}`: R version name (from preference or default)
- `{MOJO_VERSION}`: Mojo version (from preference or default)

Default values:

| Preference | Description | Default Value |
|------------|-------------|---------------|
| `mode` | The REPL mode to use | `"julia"` |
| `python_version` | Python version shown in banner | `"3.13.1"` |
| `ipython_version` | IPython version shown in banner | `"8.32.0"` |
| `r_version` | R version shown in banner | `"4.4.2"` |
| `r_version_name` | R version name shown in banner | `"Beagle Scouts"` |
| `mojo_version` | Mojo version shown in banner | `"24.6"` |
| `python_banner` | Custom banner template for Python mode | *(see below)* |
| `ipython_banner` | Custom banner template for IPython mode | *(see below)* |
| `r_banner` | Custom banner template for R mode | *(see below)* |
| `mojo_banner` | Custom banner template for Mojo mode | *(see below)* |
