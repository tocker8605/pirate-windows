extends RefCounted
## Independent seconds per owner and named attack. Windows describe intentional rests.
const EPSILON: float = 0.0000001
static func advance(owner: Dictionary, channels: Array, seconds: float, enabled: Callable) -> Array:
	var events: Array = []
	if seconds<=0 or channels.is_empty(): return events
	var age: float = float(owner.get("fire_age",0.0))
	var timers: Dictionary = owner.get("fire_timers",{})
	for index in range(channels.size()):
		var channel: Dictionary = channels[index]
		var key: String = channel.name
		if not enabled.call(channel):
			timers[key] = 0.0
			continue
		var interval: float = channel.interval_seconds
		var elapsed: float = float(timers.get(key,0.0))
		for segment in segments(channel,age,seconds):
			if not segment.enabled:
				elapsed = 0.0
				continue
			elapsed += segment.duration
			while elapsed>=interval-EPSILON:
				elapsed = maxf(0,elapsed-interval)
				var at: float = segment.start+segment.duration-elapsed
				if in_window(channel,at): events.append({"name":key,"at":at,"order":index})
		timers[key] = elapsed if in_window(channel,age+seconds) else 0.0
	owner.fire_age = age+seconds
	owner.fire_timers = timers
	if events.size()>1: events.sort_custom(func(a,b): return a.at<b.at if not is_equal_approx(a.at,b.at) else a.order<b.order)
	return events
static func in_window(channel: Dictionary, age: float) -> bool:
	if not channel.has("window_seconds"): return true
	var window: Array = channel.window_seconds
	var position: float = fposmod(age+EPSILON,float(window[0]))
	return position>=float(window[1]) and position<float(window[2])
static func segments(channel: Dictionary, age: float, seconds: float) -> Array:
	if not channel.has("window_seconds"): return [{"start":age,"duration":seconds,"enabled":true}]
	var window: Array = channel.window_seconds
	var period: float = window[0]
	var cursor: float = age
	var finish: float = age+seconds
	var result: Array = []
	while cursor<finish-EPSILON:
		var cycle: float = floorf((cursor+EPSILON)/period)*period
		var next: float = finish
		for boundary in [cycle+float(window[1]),cycle+float(window[2]),cycle+period,cycle+period+float(window[1])]:
			if boundary>cursor+EPSILON: next = minf(next,boundary)
		result.append({"start":cursor,"duration":next-cursor,"enabled":in_window(channel,cursor)})
		cursor = next
	return result
