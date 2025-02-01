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

You can customize various aspects of SneakyREPL using Julia's Preferences system. Set these in your Julia startup file (`~/.julia/config/startup.jl`):

```julia
using Preferences

# Set preferred REPL mode
@set_preferences!("mode" => "python")  # or "julia", "ipython", "r", or "mojo"

# Customize version numbers shown in banners
@set_preferences!("python_version" => "3.13.1")
@set_preferences!("ipython_version" => "8.32.0")
@set_preferences!("r_version" => "4.4.2")
@set_preferences!("r_version_name" => "Beagle Scouts")
@set_preferences!("mojo_version" => "24.6")

# Customize entire banners
@set_preferences!("python_banner" => """
Python {PYTHON_VERSION} (Julia {JULIA_VERSION})
Type "help", "copyright", "credits" or "license" for more information.
""")

@set_preferences!("ipython_banner" => """
Python {PYTHON_VERSION} (Julia {JULIA_VERSION})
Type "copyright", "credits" or "license" for more information.
IPython {IPYTHON_VERSION} -- An enhanced Interactive Python. Type '?' for help.
""")

@set_preferences!("r_banner" => """
R version {R_VERSION} (Julia {JULIA_VERSION}) -- "{R_VERSION_NAME}"
Copyright (C) 2023 The R Foundation for Statistical Computing
Platform: {MACHINE} ({WORD_SIZE}-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

Natural language support but running in an English locale

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.
""")

@set_preferences!("mojo_banner" => """
Welcome to Mojo! 🔥 (Julia {JULIA_VERSION})
Expressions are delimited by a blank line.
Type `:mojo help` for further assistance.
""")
```

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
- `mode`: "julia"
- `python_version`: "3.13.1"
- `ipython_version`: "8.32.0"
- `r_version`: "4.4.2"
- `r_version_name`: "Beagle Scouts"
- `mojo_version`: "24.6"
