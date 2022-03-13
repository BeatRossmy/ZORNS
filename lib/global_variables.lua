OCTAVE = {"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"}

NOTE_NAMES = {
  "C","C#","D","D#","E","F","F#","G","G#","A","A#","B",
  "C","C#","D","D#","E","F","F#","G","G#","A","A#","B",
  "C","C#","D","D#","E","F","F#","G","G#","A","A#","B",
  "C","C#","D","D#","E","F","F#","G","G#","A","A#","B",
  "C","C#","D","D#","E","F","F#","G","G#","A","A#","B",
  "C","C#","D","D#","E","F","F#","G","G#","A","A#","B",
  "C","C#","D","D#","E","F","F#","G","G#","A","A#","B",
  "C","C#","D","D#","E","F","F#","G","G#","A","A#","B",
  "C","C#","D","D#","E","F","F#","G","G#","A","A#","B",
  "C","C#","D","D#","E","F","F#","G","G#","A","A#","B"
}

MIDI_CHANNELS = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}

GATE_STATES = {"LOW","HIGH"}

-- ======================== SCALES ========================

SCALES = {
  short_names = {"major", "minor", "penta"},
  names = {"Major", "Natural Minor", "Minor Pentatonic"},
  values = {}
}
for i,n in pairs(SCALES.names) do
  SCALES.values[i] = musicutil.generate_scale (0, n, 10)
end

-- ========================= MIDI =========================

MIDI_DEVICES = {
  names = {},
  connected = {}
}
for _,d in pairs(midi.devices) do
  if d.port then
    local c = midi.connect(d.port)
    table.insert(MIDI_DEVICES.connected,c)
    local name = string.format("%.5s",d.name)..".."
    MIDI_DEVICES.names[#MIDI_DEVICES.connected] = name
  end
end
-- CCs
for _,d in pairs(MIDI_DEVICES.connected) do
  d.ccs = {}
  for ch=1,16 do
    d.ccs[ch] = {}
    for cc=1,128 do
      d.ccs[ch][cc] = 0
    end
  end
  d.event = function (data)
    local msg = midi.to_msg(data)
    if msg.type=="cc" then
      d.ccs[msg.ch][msg.cc] = msg.val 
    end
  end
end


-- ========================= EURYTM =========================

EURYTM = {}
for l=1,64 do
  EURYTM [l] = {}
  for p=0,l do
    EURYTM[l][p] = er.gen(p,l,0)
  end
end