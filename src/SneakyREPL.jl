module SneakyREPL

using Preferences: @load_preference, @set_preferences!

"""
    enable(mode=nothing)

Enable a specific REPL mode. If `mode` is nothing, use the preferred mode from Preferences
(defaulting to "julia" if no preference is set).

Valid modes are:
- "julia": Regular Julia REPL (default)
- "python": Python-like REPL
- "ipython": IPython-like REPL with input numbering
- "r": R-like REPL
- "mojo": Mojo-like REPL with input numbering

# Examples
```julia
enable("python")   # Enable Python mode
enable("ipython")  # Enable IPython mode
enable("r")       # Enable R mode
enable("mojo")    # Enable Mojo mode
enable("julia")    # Reset to original Julia mode
enable()          # Use preferred mode from Preferences
```
"""
function enable end

module Internals

using REPL: REPL
using Preferences: @load_preference
import ..SneakyREPL: enable

# Store original REPL settings
const ORIGINAL_SETTINGS = Dict{Symbol,Any}()

const DEFAULT_PYTHON_VERSION = "3.13.1"
const DEFAULT_IPYTHON_VERSION = "8.32.0"
const DEFAULT_R_VERSION = "4.4.2"
const DEFAULT_R_VERSION_NAME = "Beagle Scouts"

const DEFAULT_PYTHON_BANNER = """
Python {PYTHON_VERSION} (Julia {JULIA_VERSION})
Type "help", "copyright", "credits" or "license" for more information.
"""

const DEFAULT_IPYTHON_BANNER = """
Python {PYTHON_VERSION} (Julia {JULIA_VERSION})
Type "copyright", "credits" or "license" for more information.
IPython {IPYTHON_VERSION} -- An enhanced Interactive Python. Type '?' for help.

"""

const DEFAULT_R_BANNER = """

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

"""

const DEFAULT_MOJO_VERSION = "24.6"
const DEFAULT_MOJO_BANNER = """
Welcome to Mojo! 🔥
Expressions are delimited by a blank line.
Type `:mojo help` for further assistance.
"""

# Counter for input prompts
const PROMPT_COUNT = Ref(1)

# Helper function to configure on_done with counter increment
function configure_counting_on_done(main_mode)
    old_on_done = ORIGINAL_SETTINGS[:on_done]
    main_mode.on_done = (s, buf, ok) -> begin
        result = old_on_done(s, buf, ok)
        PROMPT_COUNT[] += 1
        return result
    end
end

# Function to process banner templates
function process_banner_template(template::String)
    return replace(template,
        "{JULIA_VERSION}" => Base.VERSION,
        "{MACHINE}" => Sys.MACHINE,
        "{PYTHON_VERSION}" => @load_preference("python_version", DEFAULT_PYTHON_VERSION),
        "{IPYTHON_VERSION}" => @load_preference("ipython_version", DEFAULT_IPYTHON_VERSION),
        "{R_VERSION}" => @load_preference("r_version", DEFAULT_R_VERSION),
        "{R_VERSION_NAME}" => @load_preference("r_version_name", DEFAULT_R_VERSION_NAME),
        "{MOJO_VERSION}" => @load_preference("mojo_version", DEFAULT_MOJO_VERSION),
        "{WORD_SIZE}" => Sys.WORD_SIZE
    )
end

function python_banner(io::IO=stdout)
    banner = @load_preference("python_banner", DEFAULT_PYTHON_BANNER)::String
    print(io, process_banner_template(banner))
end

function ipython_banner(io::IO=stdout)
    banner = @load_preference("ipython_banner", DEFAULT_IPYTHON_BANNER)::String
    print(io, process_banner_template(banner))
end

function r_banner(io::IO=stdout)
    banner = @load_preference("r_banner", DEFAULT_R_BANNER)::String
    print(io, process_banner_template(banner))
end

function mojo_banner(io::IO=stdout)
    banner = @load_preference("mojo_banner", DEFAULT_MOJO_BANNER)::String
    print(io, process_banner_template(banner))
end

function save_or_restore_original_settings!(repl)
    if !isdefined(repl, :interface)
        return
    end

    interface = repl.interface
    main_mode = interface.modes[1]

    if isempty(ORIGINAL_SETTINGS)
        # Save mode - store original settings
        ORIGINAL_SETTINGS[:prompt] = main_mode.prompt
        ORIGINAL_SETTINGS[:prompt_prefix] = main_mode.prompt_prefix
        ORIGINAL_SETTINGS[:prompt_suffix] = main_mode.prompt_suffix
        ORIGINAL_SETTINGS[:output_prefix] = main_mode.output_prefix
        ORIGINAL_SETTINGS[:output_prefix_prefix] = main_mode.output_prefix_prefix
        ORIGINAL_SETTINGS[:output_prefix_suffix] = main_mode.output_prefix_suffix
        ORIGINAL_SETTINGS[:on_done] = main_mode.on_done
        ORIGINAL_SETTINGS[:banner] = isdefined(Base, :banner) ? Base.banner : REPL.banner
    else
        # Restore mode - restore original settings
        main_mode.prompt = ORIGINAL_SETTINGS[:prompt]
        main_mode.prompt_prefix = ORIGINAL_SETTINGS[:prompt_prefix]
        main_mode.prompt_suffix = ORIGINAL_SETTINGS[:prompt_suffix]
        main_mode.output_prefix = ORIGINAL_SETTINGS[:output_prefix]
        main_mode.output_prefix_prefix = ORIGINAL_SETTINGS[:output_prefix_prefix]
        main_mode.output_prefix_suffix = ORIGINAL_SETTINGS[:output_prefix_suffix]
        main_mode.on_done = ORIGINAL_SETTINGS[:on_done]
    end
end

# Helper function to ensure REPL interface exists
function ensure_repl_interface(repl)
    if !isdefined(repl, :interface)
        repl.interface = REPL.setup_interface(repl)
    end
    return repl.interface
end

function enable_python_repl(repl)
    interface = ensure_repl_interface(repl)
    save_or_restore_original_settings!(repl)  # Save if empty, restore if not

    main_mode = interface.modes[1]
    main_mode.prompt = ">>> "
    main_mode.prompt_prefix = ""
    main_mode.prompt_suffix = ""
end

function enable_ipython_repl(repl)
    interface = ensure_repl_interface(repl)
    save_or_restore_original_settings!(repl)  # Save if empty, restore if not

    main_mode = interface.modes[1]

    # Set up prompt function that increments counter
    main_mode.prompt = () -> "In [$(PROMPT_COUNT[])]: "
    main_mode.prompt_prefix = ""
    main_mode.prompt_suffix = ""

    # Configure output prefix to match IPython style
    main_mode.output_prefix = "Out[$(PROMPT_COUNT[])]: "
    main_mode.output_prefix_prefix = ""
    main_mode.output_prefix_suffix = ""

    configure_counting_on_done(main_mode)
end

function enable_julia_repl(repl)
    if !isempty(ORIGINAL_SETTINGS) && isdefined(repl, :interface)
        save_or_restore_original_settings!(repl)  # Will restore since ORIGINAL_SETTINGS is not empty
        PROMPT_COUNT[] = 1  # Reset prompt counter
    end
end

function enable_r_repl(repl)
    interface = ensure_repl_interface(repl)
    save_or_restore_original_settings!(repl)  # Save if empty, restore if not

    main_mode = interface.modes[1]
    main_mode.prompt = "> "
    main_mode.prompt_prefix = ""
    main_mode.prompt_suffix = ""
    main_mode.output_prefix = "[1] "
    main_mode.output_prefix_prefix = ""
    main_mode.output_prefix_suffix = ""
end

function enable_mojo_repl(repl)
    interface = ensure_repl_interface(repl)
    save_or_restore_original_settings!(repl)  # Save if empty, restore if not

    main_mode = interface.modes[1]
    main_mode.prompt = () -> "$(PROMPT_COUNT[])> "
    main_mode.prompt_prefix = ""
    main_mode.prompt_suffix = ""

    configure_counting_on_done(main_mode)
end

function apply_repl_config(config_fn::Function)
    # Handle both pre and post REPL initialization cases
    if isdefined(Base, :active_repl) && Base.active_repl !== nothing
        # REPL is already initialized, modify it directly
        config_fn(Base.active_repl)
    else
        # REPL not yet initialized, use atreplinit
        atreplinit(config_fn)
    end

    nothing
end

# Helper function to override banner
function override_banner(banner_fn::Function)
    mod = isdefined(Base, :banner) ? Base : REPL
    @eval function $mod.banner(io::IO=stdout; short::Bool=false)
        $banner_fn(io)
    end
end

function enable_python()
    override_banner(python_banner)
    apply_repl_config(enable_python_repl)
end

function enable_ipython()
    override_banner(ipython_banner)
    apply_repl_config(enable_ipython_repl)
end

function enable_julia()
    apply_repl_config(enable_julia_repl)
end

function enable_r()
    override_banner(r_banner)
    apply_repl_config(enable_r_repl)
end

function enable_mojo()
    override_banner(mojo_banner)
    apply_repl_config(enable_mojo_repl)
end

function enable(mode::Union{String,Nothing}=nothing)
    if isnothing(mode)
        # Get preferred mode from Preferences, default to "julia"
        mode = @load_preference("mode", "julia")::String
    end

    if mode == "python"
        enable_python()
    elseif mode == "ipython"
        enable_ipython()
    elseif mode == "r"
        enable_r()
    elseif mode == "julia"
        enable_julia()
    elseif mode == "mojo"
        enable_mojo()
    else
        throw(ArgumentError("Invalid mode: $mode. Valid modes are \"julia\", \"python\", \"ipython\", \"r\", or \"mojo\"."))
    end
end

end # module Internals

end # module SneakyREPL
