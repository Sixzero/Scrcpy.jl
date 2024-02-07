module Scrcpy

greet() = print("Hello World!")
include("control.jl")
using .Control

include("scrcpy_connect.jl")
using .ScrcpyConnect

include("stream.jl")
using .Stream

# control stuff
export set_swipe_position, swipe
# connection stuff
export initialize_scrcpy_control
# frame stream stuff
export get_stream

end # module Scrcpy
