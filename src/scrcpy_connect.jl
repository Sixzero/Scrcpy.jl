module ScrcpyConnect

using Sockets
using Printf
using PyCall
using DataStructures: Queue
using ..Control: TouchState

function deploy_server(adb_path, server_file_path, port, max_size, bitrate, max_fps, video=false)
	# Upload JAR using ADB
	adb_push_command = `$adb_path push $server_file_path /data/local/tmp/scrcpy-server_julia.jar`
	@printf("Executing command: %s\n", adb_push_command)
	run(adb_push_command)

	# Building the server command
	server_command = `$adb_path shell CLASSPATH=/data/local/tmp/scrcpy-server_julia.jar app_process / com.genymobile.scrcpy.Server 2.3.1 log_level=info tunnel_forward=true video=$video audio=false control=true cleanup=false video_bit_rate=$bitrate max_fps=$max_fps max_size=$max_size`
	@printf("Executing command: %s\n", server_command)
	run(server_command, wait=false)
	
	sleep(1)
	# Forward server port
	forward_command = `$adb_path forward tcp:$port localabstract:scrcpy`
	run(forward_command)
	@printf("Port forwarded: tcp:%d -> localabstract:scrcpy\n", port)

	return true
end

function init_server_connection(ip, port, video=false)
		# Connecting video socket
		local video_socket
		if video
			@info("Connecting video socket")
			video_socket = Sockets.TCPSocket()
			Sockets.connect(video_socket, ip, port)

			# Receive dummy byte
			dummy_byte = read(video_socket, 1)
			isempty(dummy_byte) && throw(ConnectionError("Did not receive Dummy Byte!"))
		else
			video_socket = nothing
		end
		# Connecting control socket
		@info("Connecting control socket")
		control_socket = Sockets.TCPSocket()
		Sockets.connect(control_socket, ip, port)

		if video
			# Receive device name
			device_name = String(read(video_socket, 64))
			isempty(device_name) && throw(ConnectionError("Did not receive Device Name!"))
			@info("Device Name: $device_name")

			# Get codec name
			codec_name = String(read(video_socket, 4))
			@info("Codec: $codec_name")

			# Get screen resolution
			vid_width_bytes = read(video_socket, 4)
			vid_height_bytes = read(video_socket, 4)
			vid_width = ntoh(reinterpret(UInt16, vid_width_bytes)[2])

			resolution = (ntoh(reinterpret(UInt16, vid_width_bytes)[2]), ntoh(reinterpret(UInt16, vid_height_bytes)[2]))
			@info("Screen resolution: $(Int.(resolution))")
		else
			resolution = (1200,544) # this is now faked
			@info("Screen resolution faked: $(Int.(resolution))")
		end
		return video_socket, control_socket, resolution
end

# a suboptimal way to process h264 from julia, TODO improve it
py"""
# h264_processing.py
import av
import socket
from time import time
codec = av.codec.CodecContext.create('h264', 'r')

def process_h264_to_frames(raw_h264):
		start_time = time()
		try:
				packets = codec.parse(raw_h264)

				if not packets:
						return None, time()-start_time

				result_frames = []

				for packet in packets:
						frames = codec.decode(packet)
						for frame in frames:
								result_frames.append(frame.to_ndarray(format='rgb24'))

				return result_frames, time()-start_time

		except socket.error as e:
				print(f"Socket error: {e}")
				return None, time()-start_time
"""

function get_next_frames(video_socket, packet_read_size=0x2222)
	# Initialize the codec
	# Read raw H264 data from the socket
	raw_h264 = read(video_socket, packet_read_size)
	if isempty(raw_h264)
			return nothing
	end
	frames, pythontime = py"process_h264_to_frames"(raw_h264)
	frames
end

function initialize_scrcpy_control(video=false, max_size=1200, bitrate=8_000_000, max_fps=30)
	ip, port = "127.0.0.1", 8081

	cfd = dirname(@__DIR__) # current file directory

	deploy_server("adb", "$cfd/assets/scrcpy-server-v2.3.1_master", port, max_size, bitrate, max_fps, video)
	video_socket, ctrl_socket, res = init_server_connection(ip, port, video)
	state = TouchState(false, (0,0), ctrl_socket, Int.(res))
	video_socket, ctrl_socket, state
end


function stream_to_ffmpeg(socket::TCPSocket)
    # Construct the ffmpeg command
    ffmpeg_cmd = `ffmpeg -i pipe:0 -f image2pipe -vcodec png -pix_fmt rgb24 -r 10 -`

    # Spawn ffmpeg process
    ffmpeg_process = Base.open(ffmpeg_cmd, "w")

    try
        while isopen(socket)
            data = readavailable(socket)
            write(ffmpeg_process, data)
        end
    catch e
        println("Error: $e")
    finally
        close(ffmpeg_process)
    end
end
export initialize_scrcpy_control
# # Example usage
# # Assuming 'video_socket' is an already connected TCPSocket receiving video data
# video_socket = Sockets.TCPSocket()
# stream_to_ffmpeg(video_socket)


end # module ScrcpyConnect