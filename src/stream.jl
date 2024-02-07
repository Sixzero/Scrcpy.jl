module Stream

using VideoIO
function check_scrcpy_running(device)
  cmd = `pgrep -f "scrcpy.*--v4l2-sink=$device"`
  try
      process_output = read(cmd, String)
      @show process_output
      return !isempty(process_output)
  catch e
    @show e
    @show isa(e, Base.IOError)
    @show sprint(showerror, e)
    @show occursin("failed process", sprint(showerror, e))
    if occursin("failed process", sprint(showerror, e))
      println("pgrep did not find any matching processes.")
      return false
    else
      rethrow(e)  # Rethrow the error if it's not the expected "no matches found" case
    end
  end
end
# Use this to get frame = read(cap) to get the next frame from the mobile video stream (camera)
function get_stream(fps=15, max_width=1200, device="/dev/video0")
  scrcpy_status = check_scrcpy_running(device)
  @show scrcpy_status
  if !scrcpy_status
    !ispath(device) && run(`sudo modprobe v4l2loopback`)
    process = run(`scrcpy --max-fps $fps -m $max_width --v4l2-sink=$device`, wait=false)
    @show "Starting scrcpy"
    sleep(5)
    @show process
  end
  cap = VideoIO.opencamera(device)

  if !isopen(cap)
    error("Failed to open video device: $device")
  end
  cap
end
export get_stream

end # module Stream