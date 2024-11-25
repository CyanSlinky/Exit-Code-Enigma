extends AudioStreamPlayer

@export var min_distance: float = 1.0  # Distance at which volume is maximum
@export var max_distance: float = 50.0  # Distance beyond which volume is zero

var noise_pulse_chance: float = 0.0002  # Chance of a noise pulse
var pulse_duration: float = 0.1  # Duration of the pulse (seconds)
var time_variation: float = 0.001  # Amount of variation in time steps

func update_volume() -> void:
	if GameData.player and GameData.office_manager:
		var dist: float = GameData.player.global_transform.origin.distance_to(GameData.office_manager.global_transform.origin)
		var volume: float = clamp(1.0 - (dist - min_distance) / (max_distance - min_distance), 0.0, 1.0)
		self.volume_db = linear_to_db(volume)

func _ready() -> void:
	var generator: AudioStreamGenerator = AudioStreamGenerator.new()
	generator.mix_rate = 44100  # Set sample rate
	generator.buffer_length = 0.5  # Buffer size in seconds
	self.stream = generator  # Assign the generator to the AudioStreamPlayer
	
	self.play()  # Start playback to initialize the playback object
	
	# Wait for the playback object to be ready
	var playback: AudioStreamGeneratorPlayback = self.get_stream_playback() as AudioStreamGeneratorPlayback
	while playback == null:
		await get_tree().process_frame  # Wait for the next frame
		playback = self.get_stream_playback() as AudioStreamGeneratorPlayback
	
	# Start generating sound in a loop
	await generate_looping_sound(playback, int(generator.mix_rate))

# Continuously generates and pushes sound frames into the buffer
func generate_looping_sound(playback: AudioStreamGeneratorPlayback, mix_rate: int) -> void:
	var phase: float = 0.0  # Keeps track of the waveform phase
	var base_frequency: float = 20.0  # Frequency of the sine wave (in Hz)
	var frequency_variation: float = 0.0  # Max deviation from the base frequency
	var noise_level: float = 0.05  # Amount of noise to add
	var amplitude: float = 0.5  # Base amplitude
	var modulation_speed: float = 0.1  # Frequency of the amplitude modulation (in Hz)
	#var pan_speed: float = 0.05  # Speed of panning modulation
	
	while true:
		# Wait until the buffer has space for more frames
		while playback.get_frames_available() < mix_rate * 0.1:  # Wait if less than 0.1 seconds of space
			await get_tree().process_frame  # Yield to avoid blocking the main thread
		
		# Generate and push frames to the buffer
		var frames_to_generate: int = int(mix_rate * 0.1)  # Generate 0.1 seconds of audio at a time
		for i in range(frames_to_generate):
			var t: float = phase / mix_rate  # Time in seconds
			var modulated_frequency: float = base_frequency + randf() * frequency_variation - (frequency_variation / 2.0)
			var modulated_amplitude: float = amplitude + sin(2 * PI * modulation_speed * t) * 0.1
			var layer1: float = modulated_amplitude * sin(2 * PI * modulated_frequency * t)  # Main sine wave
			var layer2: float = 0.3 * sin(2 * PI * (modulated_frequency * 1.5) * t)  # Higher-pitched, quieter wave
			var noise: float = randf() * noise_level - (noise_level / 2.0)  # White noise
			var value: float = layer1 + layer2 + noise
			
			if randf() < noise_pulse_chance:
				value += (randf() - 0.5) * 1.8  # Add a short, loud noise burst
			
			#var pan: float = (sin(2 * PI * pan_speed * t) + 1.0) / 2.0
			var frame: Vector2 = Vector2(value, value)  # Same value for both channels (mono to stereo)
			playback.push_frame(frame)
			phase += 1
			if phase >= mix_rate:
				phase -= mix_rate  # Keep phase within one cycle
		
		update_volume()
