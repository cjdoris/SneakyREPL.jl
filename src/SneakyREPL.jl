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

# Examples
```julia
enable("python")   # Enable Python mode
enable("ipython")  # Enable IPython mode
enable("r")       # Enable R mode
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

const DEFAULT_PYTHON_BANNER = """
Python 3.9.0 (Julia $(VERSION)) on $(Sys.MACHINE)
Type "help", "copyright", "credits" or "license" for more information.
"""

const DEFAULT_IPYTHON_BANNER = """
IPython 8.0.0 (Julia $(VERSION))
Type '?' for help.

In [1]: """

const DEFAULT_R_BANNER = """

R version 4.3.0 (Julia $(VERSION))
Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

"""

# Counter for IPython input prompts
const IPYTHON_COUNT = Ref(1)

function python_banner(io::IO=stdout)
    banner = @load_preference("python_banner", DEFAULT_PYTHON_BANNER)::String
    print(io, banner)
end

function ipython_banner(io::IO=stdout)
    banner = @load_preference("ipython_banner", DEFAULT_IPYTHON_BANNER)::String
    print(io, banner)
end

function r_banner(io::IO=stdout)
    banner = @load_preference("r_banner", DEFAULT_R_BANNER)::String
    print(io, banner)
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

function enable_python_repl(repl)
    if !isdefined(repl, :interface)
        interface = repl.interface = REPL.setup_interface(repl)
    else
        interface = repl.interface
    end
    save_or_restore_original_settings!(repl)  # Save if empty, restore if not

    main_mode = interface.modes[1]
    main_mode.prompt = ">>> "
    main_mode.prompt_prefix = ""
    main_mode.prompt_suffix = ""
end

function enable_ipython_repl(repl)
    if !isdefined(repl, :interface)
        interface = repl.interface = REPL.setup_interface(repl)
    else
        interface = repl.interface
    end
    save_or_restore_original_settings!(repl)  # Save if empty, restore if not

    main_mode = interface.modes[1]

    # Set up prompt function that increments counter
    main_mode.prompt = () -> "In [$(IPYTHON_COUNT[])]: "
    main_mode.prompt_prefix = ""
    main_mode.prompt_suffix = ""

    # Configure output prefix to match IPython style
    main_mode.output_prefix = "Out[$(IPYTHON_COUNT[])]: "
    main_mode.output_prefix_prefix = ""
    main_mode.output_prefix_suffix = ""

    # Hook into on_done to increment counter after each input
    old_on_done = ORIGINAL_SETTINGS[:on_done]  # Use saved original on_done
    main_mode.on_done = (s, buf, ok) -> begin
        result = old_on_done(s, buf, ok)
        IPYTHON_COUNT[] += 1
        return result
    end
end

function enable_julia_repl(repl)
    if !isempty(ORIGINAL_SETTINGS) && isdefined(repl, :interface)
        save_or_restore_original_settings!(repl)  # Will restore since ORIGINAL_SETTINGS is not empty
        IPYTHON_COUNT[] = 1  # Reset IPython counter
    end
end

function enable_r_repl(repl)
    if !isdefined(repl, :interface)
        interface = repl.interface = REPL.setup_interface(repl)
    else
        interface = repl.interface
    end
    save_or_restore_original_settings!(repl)  # Save if empty, restore if not

    main_mode = interface.modes[1]
    main_mode.prompt = "> "
    main_mode.prompt_prefix = ""
    main_mode.prompt_suffix = ""
    main_mode.output_prefix = "[1] "
    main_mode.output_prefix_prefix = ""
    main_mode.output_prefix_suffix = ""
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

function enable_python()
    # Override banner function in the correct module depending on Julia version
    mod = isdefined(Base, :banner) ? Base : REPL
    @eval function $mod.banner(io::IO=stdout; short::Bool=false)
        $python_banner(io)
    end

    apply_repl_config(enable_python_repl)
end

function enable_ipython()
    # Override banner function in the correct module depending on Julia version
    mod = isdefined(Base, :banner) ? Base : REPL
    @eval function $mod.banner(io::IO=stdout; short::Bool=false)
        $ipython_banner(io)
    end

    apply_repl_config(enable_ipython_repl)
end

function enable_julia()
    apply_repl_config(enable_julia_repl)
end

function enable_r()
    # Override banner function in the correct module depending on Julia version
    mod = isdefined(Base, :banner) ? Base : REPL
    @eval function $mod.banner(io::IO=stdout; short::Bool=false)
        $r_banner(io)
    end

    apply_repl_config(enable_r_repl)
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
    else
        throw(ArgumentError("Invalid mode: $mode. Valid modes are \"julia\", \"python\", \"ipython\", or \"r\"."))
    end
end

end # module Internals

end # module SneakyREPL
