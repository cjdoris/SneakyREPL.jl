module SneakyREPL

"""
    enable(mode=nothing)

Enable a specific REPL mode. If `mode` is nothing, use the preferred mode from Preferences
(defaulting to "julia" if no preference is set).

Valid modes are:
- "julia": Regular Julia REPL (default)
- "python": Python-like REPL

# Examples
```julia
enable("python")  # Enable Python mode
enable("julia")   # Reset to original Julia mode
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

const PYTHON_BANNER = """
Python 3.9.0 (Julia $(VERSION)) on $(Sys.MACHINE)
Type "help", "copyright", "credits" or "license" for more information.
"""

function python_banner(io::IO=stdout)
    print(io, PYTHON_BANNER)
end

function save_original_settings!(repl)
    if isempty(ORIGINAL_SETTINGS) && isdefined(repl, :interface)
        interface = repl.interface
        main_mode = interface.modes[1]
        ORIGINAL_SETTINGS[:prompt] = main_mode.prompt
        ORIGINAL_SETTINGS[:prompt_prefix] = main_mode.prompt_prefix
        ORIGINAL_SETTINGS[:prompt_suffix] = main_mode.prompt_suffix
        # Save the original banner function
        ORIGINAL_SETTINGS[:banner] = isdefined(Base, :banner) ? Base.banner : REPL.banner
    end
end

function enable_python_repl(repl)
    if !isdefined(repl, :interface)
        interface = repl.interface = REPL.setup_interface(repl)
    else
        interface = repl.interface
    end
    save_original_settings!(repl)
    main_mode = interface.modes[1]
    main_mode.prompt = ">>> "
    main_mode.prompt_prefix = ""
    main_mode.prompt_suffix = ""
end

function enable_julia_repl(repl)
    if !isempty(ORIGINAL_SETTINGS) && isdefined(repl, :interface)
        interface = repl.interface
        main_mode = interface.modes[1]
        main_mode.prompt = ORIGINAL_SETTINGS[:prompt]
        main_mode.prompt_prefix = ORIGINAL_SETTINGS[:prompt_prefix]
        main_mode.prompt_suffix = ORIGINAL_SETTINGS[:prompt_suffix]
    end
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

function enable_julia()
    apply_repl_config(enable_julia_repl)
end

function enable(mode::Union{String,Nothing}=nothing)
    if isnothing(mode)
        # Get preferred mode from Preferences, default to "julia"
        mode = @load_preference("mode", "julia")::String
    end

    if mode == "python"
        enable_python()
    elseif mode == "julia"
        enable_julia()
    else
        throw(ArgumentError("Invalid mode: $mode. Valid modes are \"julia\" or \"python\"."))
    end
end

end # module Internals

end # module SneakyREPL
