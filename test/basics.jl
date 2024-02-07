using Scrcpy

video_socket, ctrl_socket, state = initialize_scrcpy_control(true, 1200)
#%%
using Scrcpy: swipe

swipe(state, 300,300, 200,200)
#%%
using Scrcpy: get_stream
device::String = "/dev/video0"
cap = get_stream(device)

frame = read(cap)
#%%
@show size(frame)
@show typeof(frame)
frame = read(cap)