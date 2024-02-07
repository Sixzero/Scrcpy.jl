# ScrcpyConnect.jl

`ScrcpyConnect.jl` is a Julia wrapper for `scrcpy`, allowing users to stream their mobile device's screen to their computer and simulate touch events via a socket connection. This package enables high-level control and interaction with Android devices for applications ranging from automated testing to remote control. 

## Features

- Stream mobile device screen to a computer in real-time
- Simulate touch events (tap, swipe) on the device from Julia
- Efficient communication via scrcpy's socket connections

## Installation

To use `Scrcpy.jl`, you can add `Scrcpy` using Julia's package manager.

```julia
using Pkg
Pkg.add("https://github.com/Sixzero/Scrcpy.jl.git")
``````
Make sure you have scrcpy and adb (Android Debug Bridge) installed on your system as these are required for the package to function.

## Usage
Initializing the Connection
First, ensure your Android device is connected to your computer and USB debugging is enabled.

```julia
using Scrcpy
# Initialize the scrcpy server and establish a connection
video_socket, ctrl_socket, state = ScrcpyConnect.initialize_scrcpy_control(video=true, max_size=1200)
```
## Streaming the Screen
To access the video frames directly in Julia for processing or analysis. This requires an active video_socket.
```julia
using Scrcpy: get_stream

device = "/dev/video0"  # Device file for the video stream, this will get created. This is basically going to be used as a camera source, which will be used by `scrcpy --max-fps $fps -m $max_width --v4l2-sink=$device``
cap = get_stream(device, fps, max_width) # set fps and max_width of stream
# Capture a frame from the video stream
frame = read(cap)
```
## Simulating Touch Events
You can simulate touch events such as tap and swipe using the control socket.
```julia
# Simulate a tap at coordinates (300, 300)
tap(state, 300, 300)

# Simulate a swipe from (300, 300) to (200, 200)
swipe(state, 300, 300, 200, 200) 

# Swipe without releasing the at the end of swipe, so drags/swipes can be continued:
set_swipe(state, 300,300, -100,-100) # if 
set_swipe(state, 1111,300, -110,-110) # if it is not relased between the two, then the touch position doesn't matter the Δx and Δy matters from the initial 300,300 position and 1111,300 doesn't matter in this case. This seemed a reasonable approach, but I am curious what the best idea for this interface would be, the possibilities are unlimited with scrcpy. 

```

## Advanced Usage
For more advanced usage, including customizing the video stream's properties and handling touch events more granely, refer to the module documentation within the code.

## Contributing
Contributions to Scrcpy.jl are welcome! Please refer to the CONTRIBUTING.md for guidelines.

## License
Scrcpy.jl is released under the MIT License. See the LICENSE file for more details.

