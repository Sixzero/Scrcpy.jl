module Control

using Sockets
using Base: hton

export tap, swipe, set_swipe, TouchState

mutable struct TouchState
  in_touch::Bool
  current_touch_start::Tuple{Int, Int}
  control_socket::Union{TCPSocket, Nothing}
  resolution::Union{Tuple{Int, Int}, Nothing}
end

const ACTION_DOWN = 0x00
const ACTION_UP = 0x01
const ACTION_MOVE = 0x02

function int32_to_big_endian_bytes(val::Int32)
  return [(val >> 24) & 0xFF, (val >> 16) & 0xFF, (val >> 8) & 0xFF, val & 0xFF]
end
function int32_to_big_endian_bytes(val::UInt16)
  return [(val >> 8) & 0xFF, val & 0xFF]
end
function build_touch_message(state::TouchState, x::Int, y::Int, action::UInt8)
    b = UInt8[0x02, action]
    @show x, y, action

    append!(b, [0x12, 0x34, 0x56, 0x78, 0x87, 0x65, 0x43, 0x21])
    append!(b, int32_to_big_endian_bytes.(Int32[x, y])...)  # Convert x and y to network byte order and append
    append!(b, int32_to_big_endian_bytes.(UInt16[state.resolution...])...)  # Convert resolution to network byte order and append
    append!(b, [0xff, 0xff])  # Pressure
    append!(b, [0x00, 0x00, 0x00, 0x01])  # Event button primary
    append!(b, [0x00, 0x00, 0x00, 0x01])  # Event button primary

    return b
end

function send_touch_event(state::TouchState, x::Int, y::Int, action::UInt8)
  message = build_touch_message(state, x, y, action)
  write(state.control_socket, message)
end

function send_touch_DOWN(state, x, y)
  send_touch_event(state, x, y, ACTION_DOWN)
  state.current_touch_start = (x, y)
end
function send_touch_MOVE(state, x, y)
  send_touch_event(state, x, y, ACTION_MOVE)
end
function send_touch_UP(state)
  send_touch_event(state, 0, 0, ACTION_UP)  # Assuming a touch up event doesn't need x, y coordinates
  state.current_touch_start = (0, 0)

end

function begin_touch(state, x, y)
  if !state.in_touch
    send_touch_DOWN(state, x, y)
    state.in_touch = true
  else
    send_touch_MOVE(state, x, y)
  end
end

function end_touch(state)
  if state.in_touch
    send_touch_UP(state)
    state.in_touch = false
  end
end

function tap(state, x, y, finish=true)
  begin_touch(state, x, y)
  if finish
    sleep(0.03)  # Short delay to mimic human tap; adjust as needed
    end_touch(state)
  end
end
function set_swipe(state, x, y, Δx, Δy, )
  if x<0 || y < 0
    end_touch(state)
    return  
  end
  if !state.in_touch
    begin_touch(state, x, y)
    sleep(0.03)
  end
  send_touch_MOVE(state, (state.current_touch_start .+ (Δx, Δy))...)
end
function denorm(state::TouchState, coord, Δcoord)
  coord = Int.(round.(coord .* state.resolution))
  Δcoord = Int.(round.(Δcoord .* state.resolution))
  coord, Δcoord
end
function swipe(state, x,y,x2,y2)
  begin_touch(state, x, y)
  sleep(0.03)  # Short delay to mimic human tap; adjust as needed
  # some more movement interpolation codes....
  send_touch_MOVE(state, x2, y2)
  sleep(0.03)  # Short delay to mimic human tap; adjust as needed
  end_touch(state)
end

end