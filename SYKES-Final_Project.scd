(
s.waitForBoot {

	//SynthDef for piano (slightly edited, but borrowed from the following link: https://doc.sccode.org/Classes/MdaPiano.html)
SynthDef(\mdapiano, { |out=0, freq=440, vel=10|

	var son = MdaPiano.ar(freq, decay: 0.2, release: 0.4, stereo: 0.3, sustain: 0);

	DetectSilence.ar(son, 0.01, doneAction:2);

	Out.ar(out, son * 0.1);

}).add;

//These are the global variables the user will adjust in the GUI
~tempo = 0.5;
~key_offset = 0;
~funkiness = 0.5;

	//formula for 3 options: [0.8 - ~funkiness, 0.4, ~funkiness - 0.2]
	//formula for 4 options: [0.7 - ~funkiness, 0.55 - (0.5 * ~funkiness), 0.05 + (0.5 * ~funkiness), -0.3 + ~funkiness]

//data for melody
~midi_template = Array.with(60, 60, 62, 60, 65, 64, 60, 60, 62, 60, 67, 65, 60, 60, 72, 69, 65, 64, 62, 70, 70, 69, 65, 67, 65);
~dur_template = Array.with(0.75, 0.25, 1, 1, 1, 2, 0.75, 0.25, 1, 1, 1, 2, 0.75, 0.25, 1, 1, 1, 1, 1, 0.75, 0.25, 1, 1, 1, 3);

//~melody is a global variable that will hold the final Pseq for the melody transposed into the proper key and played at the right tempo
~melody;

//~reset_melody is a helper function that assigns the variable ~melody to a Pseq with an array of Pbinds for the melody. This function also uses ~tempo and ~key_offset to ensure that the final melody is in the correct key and tempo (as decided by the user)
	~reset_melody = {var melody_dur = Array.new; var melody_midi = Array.new; var melody_pbinds = Array.new; ~dur_template.do({|i| melody_dur = melody_dur.add(i * ~tempo)}); ~midi_template.do({|i| melody_midi = melody_midi.add(i + ~key_offset)}); melody_midi.size.do({|i| melody_pbinds = melody_pbinds.add(Pbind(\instrument, \mdapiano, \freq, Pseq([melody_midi[i].midicps], 1), \dur, melody_dur[i], \amp, 1))}); ~melody = Pseq(melody_pbinds, 1)};

//chord durations array
	~chord_dur = Array.with(3, 3, 3, 3, 3, 3, 2, 1, 3);

//data for traditional harmonization
	~traditional_chords = Array.with([53, 57, 60], [52, 55, 60], [52, 55, 60], [53, 57, 60], [48, 53, 60], [53, 58, 62], [53, 57, 60], [52, 55, 60], [53, 57, 60]);
	~traditional_bass = Array.with(53, 48, 48, 53, 45, 46, 48, 48, 41);

//~play_traditional is a helper function that adds the key offset to the traditional harmonization stored in ~traditional_chords and ~traditional_bass, then passes the result to the ~play function
	~play_traditional = {var new_chords = Array.new; var new_bass = Array.new; ~traditional_chords.do({|i| var chord = ~add_offset.value(~key_offset, i); new_chords = new_chords.add(chord)}); ~traditional_bass.do({|i| new_bass = new_bass.add(i + ~key_offset)}); ~play.value(new_chords, new_bass)};


//~add_offset is a helper function that adds the key_offset to the midi degrees in each chord array
~add_offset = {arg key_offset, chord; var return_array = Array.new; chord.do({|i| return_array = return_array.add(i + key_offset)}); return_array};

//~reset is a function that resets the mealy machine to make a new progression
	~reset = {g.curr_chord = "Ir"; g.measure = 1; g.bass_line = []; g.new_progression = []; g.chord_names = []};

	//g is the event used to implement the harmonization-generating mealy machine.
	//NOTE: the word "measure" is used to indicate what chord we are on in the song, but the last few chords do not line up exactly with the measure lines (since there are two chords in the penultimate measure)
	g = (curr_key_offset: 0, curr_chord: "Ir", measure: 1, bass_line: [], new_progression: [], chord_names: [],
		func: {g.curr_key_offset = ~key_offset;
			case
			//case 1: I
			{g.curr_chord == "Ir"} {var to_add = ~add_offset.value(g.curr_key_offset, [53, 57, 60]); g.new_progression = g.new_progression.add(to_add); if (g.measure == 9, {g.bass_line = g.bass_line.add(41 + g.curr_key_offset)}, {g.bass_line = g.bass_line.add(53 + g.curr_key_offset)}); g.chord_names = g.chord_names.add(g.curr_chord);
				case
				{g.measure == 1} {g.curr_chord = ["V7", "VI7", "IV9"].wchoose([0.8 - ~funkiness, 0.4, ~funkiness - 0.2]); g.measure = 2}
				{g.measure == 4} {g.curr_chord = ["I1", "vi", "IV", "bVII9"].wchoose([0.7 - ~funkiness, 0.55 - (0.5 * ~funkiness), 0.05 + (0.5 * ~funkiness), -0.3 + ~funkiness]); g.measure = 5}
				{g.measure == 9} {g.curr_chord = "DONE"};
			}

			//case 2: V7
			{g.curr_chord == "V7"} {var to_add = ~add_offset.value(g.curr_key_offset, [55, 58, 64]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(48 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord);
				case
				{g.measure == 2} {g.curr_chord = ["V7", "v7", "ii7", "IV"].wchoose([0.7 - ~funkiness, 0.55 - (0.5 * ~funkiness), 0.05 + (0.5 * ~funkiness), -0.3 + ~funkiness]); g.measure = 3}
				{g.measure == 3} {g.curr_chord = ["Ir", "I7", "bVII7b5", "#IV9"].wchoose([0.7 - ~funkiness, 0.55 - (0.5 * ~funkiness), 0.05 + (0.5 * ~funkiness), -0.3 + ~funkiness]); g.measure = 4}
				{g.measure == 8} {g.curr_chord = "Ir"; g.measure = 9};
			}

			//case 3: VI7
			{g.curr_chord == "VI7"} {var to_add = ~add_offset.value(g.curr_key_offset, [54, 57, 60]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(50 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord);
				case
				{g.measure == 2} {g.curr_chord = "ii7"; g.measure = 3}
				{g.measure == 6} {g.curr_chord = ["ii7", "II7"].wchoose([1 - ~funkiness, ~funkiness]); g.measure = 7};
			}

			//case 4: v7
			{g.curr_chord == "v7"} {var to_add = ~add_offset.value(g.curr_key_offset, [51, 55, 58]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(48 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord); g.curr_chord = ["Ir", "I7", "#IV9"].wchoose([0.8 - ~funkiness, 0.4, ~funkiness - 0.2]); g.measure = 4
			}

			//case 5: ii7
			{g.curr_chord == "ii7"} {var to_add = ~add_offset.value(g.curr_key_offset, [50, 53, 58]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(43 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord);
				case
				{g.measure == 3} {g.curr_chord = "III7#5"; g.measure = 4}
				{g.measure == 5} {g.curr_chord = "IV"; g.measure = 6}
			    {g.measure == 6} {g.curr_chord = "I2"; g.measure = 7}
			    {g.measure == 7} {g.curr_chord = ["V7", "iv", "bVII9"].wchoose([0.8 - ~funkiness, 0.4, ~funkiness - 0.2]); g.measure = 8};
			}

			//case 6: IV
			{g.curr_chord == "IV"} {var to_add = ~add_offset.value(g.curr_key_offset, [53, 58, 62]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(46 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord);
				case
				{g.measure == 3} {g.curr_chord = "III7#5"; g.measure = 4}
				{g.measure == 5} {g.curr_chord = ["IV", "ii7", "II7"].wchoose([0.8 - ~funkiness, 0.4, ~funkiness - 0.2]); g.measure = 6}
				{g.measure == 6} {g.curr_chord = ["I2", "II7"].wchoose([1 - ~funkiness, ~funkiness]); g.measure = 7};
 			}

			//case 7: I7
			{g.curr_chord == "I7"} {var to_add = ~add_offset.value(g.curr_key_offset, [57, 60, 63]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(53 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord); g.curr_chord = ["IV", "bVII9"].wchoose([1 - ~funkiness, ~funkiness]); g.measure = 5
 			}

			//case 8: III7#5
			{g.curr_chord == "III7#5"} {var to_add = ~add_offset.value(g.curr_key_offset, [55, 61, 65]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(45 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord); g.curr_chord = ["vi", "IV", "bVII9"].wchoose([0.8 - ~funkiness, 0.4, ~funkiness - 0.2]); g.measure = 5
 			}

			//case 9: bVII7b5
			{g.curr_chord == "bVII7b5"} {var to_add = ~add_offset.value(g.curr_key_offset, [55, 57, 61]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(51 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord); g.curr_chord = ["IV", "ii7"].wchoose([1 - ~funkiness, ~funkiness]); g.measure = 5
 			}

			//case 10: I1
			{g.curr_chord == "I1"} {var to_add = ~add_offset.value(g.curr_key_offset, [53, 60, 65]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(45 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord); g.curr_chord = ["IV", "II7"].wchoose([1 - ~funkiness, ~funkiness]); g.measure = 6
 			}

			//case 11: vi
			{g.curr_chord == "vi"} {var to_add = ~add_offset.value(g.curr_key_offset, [57, 60, 65]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(50 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord);
				case
				{g.measure == 4} {g.curr_chord = ["IV", "ii7", "bVII9"].wchoose([0.8 - ~funkiness, 0.4, ~funkiness - 0.2]); g.measure = 5}
				{g.measure == 5} {g.curr_chord = ["ii7", "II7"].wchoose([1 - ~funkiness, ~funkiness]); g.measure = 6};
 			}

			//case 12: bVII9
			{g.curr_chord == "bVII9"} {var to_add = ~add_offset.value(g.curr_key_offset, [55, 58, 61, 65]); g.new_progression = g.new_progression.add(to_add); if (g.measure == 5, {g.bass_line = g.bass_line.add(51 + g.curr_key_offset)}, {g.bass_line = g.bass_line.add(39 + g.curr_key_offset)}); g.chord_names = g.chord_names.add(g.curr_chord);
				case
				{g.measure == 5} {g.curr_chord = "VI7"; g.measure = 6}
				{g.measure == 8} {g.curr_chord = "Ir"; g.measure = 9};
 			}

			//case 13: II7
			{g.curr_chord == "II7"} {var to_add = ~add_offset.value(g.curr_key_offset, [50, 53, 59]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(43 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord);
				case
				{g.measure == 6} {g.curr_chord = ["I2", "ii7"].wchoose([1 - ~funkiness, ~funkiness]); g.measure = 7}
				{g.measure == 7} {g.curr_chord = ["V7", "iv"].wchoose([1 - ~funkiness, ~funkiness]); g.measure = 8};
 			}

			//case 14: I2
			{g.curr_chord == "I2"} {var to_add = ~add_offset.value(g.curr_key_offset, [53, 57, 60]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(48 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord); g.curr_chord = ["V7", "iv", "bVII9"].wchoose([0.8 - ~funkiness, 0.4, ~funkiness - 0.2]); g.measure = 8
 			}

			//case 15: iv
			{g.curr_chord == "iv"} {var to_add = ~add_offset.value(g.curr_key_offset, [53, 58, 61]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(46 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord); g.curr_chord = "Ir"; g.measure = 9
			}

			//case 16: #IV9
			{g.curr_chord == "#IV9"} {var to_add = ~add_offset.value(g.curr_key_offset, [51, 54, 57, 61]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(47 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord); g.curr_chord = "IV"; g.measure = 5}

			//case 17: IV9
			{g.curr_chord == "IV9"} {var to_add = ~add_offset.value(g.curr_key_offset, [50, 53, 56, 60]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(46 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord); g.curr_chord = ["v7", "iii7"].wchoose([1 - ~funkiness, ~funkiness]); g.measure = 3}

			//case 18: iii7
			{g.curr_chord == "iii7"} {var to_add = ~add_offset.value(g.curr_key_offset, [52, 55, 60]); g.new_progression = g.new_progression.add(to_add); g.bass_line = g.bass_line.add(45 + g.curr_key_offset); g.chord_names = g.chord_names.add(g.curr_chord); g.curr_chord = ["vi", "III7#5", "#IV9"].wchoose([0.8 - ~funkiness, 0.4, ~funkiness - 0.2]); g.measure = 4};

	//return g.new_progression
	g.new_progression});


	//~generate is the main function of this program. It calls g.func to activate the mealy machine then plays and prints the resulting harmonization. It is called when the user presses the "PLAY" button
	~generate = {~reset.value(); while ({g.curr_chord != "DONE"}, {g.func}); ~reset_melody.value(); ~play.value(g.new_progression, g.bass_line); ~print_chords.value(g.chord_names)};

	//~replay calls play on the most recently generated harmonization. It is called when the user presses the "replay" button
	~replay = {if (g.new_progression == [], {"Generate at least one progression before replaying".postln}, {~play.value(g.new_progression, g.bass_line)})};

	//~make_chord is a helper function used to make Pbinds for each of the notes in a chord. These pbinds will eventually be put into a ppar so the notes of the chord are played simultaneously.
	~make_chord = {arg midi_array, dur; var pbind_array = []; midi_array.do({|i| pbind_array = pbind_array.add(Pbind(\instrument, \mdapiano, \freq, Pseq([i.midicps], 1), \dur, dur, \amp, 0.5))}); Ppar(pbind_array, 1)};

	//~play is the main function to actually play the generated harmonization. It is also called by ~replay and ~play_traditional.
	~play = {arg chords, bassline; var melody_pbind_array = Array.new; var chord_ppar_array = Array.new; var bass_pbind_array = Array.new;

		//generate chord array
		chords.size.do({|i| var new_ppar; new_ppar = ~make_chord.value(chords[i], ~chord_dur[i] * ~tempo); chord_ppar_array = chord_ppar_array.add(new_ppar)});

		//generate bassline array
		bassline.size.do({|i| bass_pbind_array = bass_pbind_array.add(Pbind(\instrument, \mdapiano, \freq, Pseq([bassline[i].midicps], 1), \dur, ~chord_dur[i] * ~tempo, \amp, 0.75))});

		//play result (note ~melody has already been initialized to the proper values since ~reset_melody is called before any calls to ~play).
		Ptpar([0, ~melody, 1 * ~tempo, Pseq(chord_ppar_array, 1), 1 * ~tempo, Pseq(bass_pbind_array, 1)], 1).play;
	};

//~print_chords is a helper function that prints the generated harmonization to the post window.
	~print_chords = {arg chord_names; "Here's your harmonization:".postln; chord_names.do({|i| postf("% ", i)}); "".postln};


	s.sync;

	//GUI information
	//~key2offset is a dictionary used to translate the user's key selection to an integer offset
	~key2offset = Dictionary.newFrom(["Choose a key", 0, "C", -5, "D flat", -4, "D", -3, "E flat", -2, "E", -1, "F", 0, "G flat", 1, "G", 2, "A flat", 3, "A", 4, "B flat", 5, "B", 6]);

	//welcome text that is presented at top of GUI with instructions
	~welcome = "Welcome to Peter's Happy Birthday Harmonizer! First select the key you want for your harmonization (if you don't choose one then it will default to F major). Then use the slide bars to choose the tempo and ~funkiness~ you want for your harmonization. The left extreme is the slowest/least funky, and the right extreme is the fastest/most funky. Press play when you're ready to hear your harmonization. Your harmonizaiton will also be printed to the post window (note \"Ir\" means the tonic chord in root position, \"I1\" means the tonic chord in first inversion, and \"I2\" means the tonic chord in second inversion). If you like your harmonization so much you want to hear it again, press the replay button. If you want to go back to basics, press the \"play traditional harmonization\" button. Have fun!";

	//main window
	w = Window.new("Happy Birthday!", Rect(500, 500, 500, 500));

	//welcome text
	r = StaticText.new(w, Rect(25, 5, 450, 190));
	r.string = ~welcome;

	//pop up menu for key selection
	m = PopUpMenu(w, Rect(190, 200, 120, 30));
	m.items = ["Choose a key", "C", "D flat", "D", "E flat", "E", "F", "G flat", "G", "A flat", "A", "B flat", "B"];

	//header for tempo slider
	t = StaticText.new(w, Rect(190, 220, 150, 50));
	t.string = "Slide to select tempo:";

	//tempo slider
	e = Slider.new(w, Rect(150, 260, 200, 30));
	e.value_(0.5);

	//header for funkiness slider
	u = StaticText.new(w, Rect(170, 280, 200, 50));
	u.string = "Slide to select ~funkiness~:";

	//funkiness slider
	f = Slider.new(w, Rect(150, 320, 200, 30));
	f.value_(0.5);

	//play button
	b = Button.new(w, Rect(200, 370, 100, 30));
	b.string = "PLAY";
	b.action = {~key_offset = ~key2offset[m.item]; ~tempo = 1.2 - (e.value); ~funkiness = f.value; ~generate.value()};

	//play traditional button
	c = Button.new(w, Rect(155, 450, 200, 30));
	c.string = "Play traditional harmonization";
	c.action = {~key_offset = ~key2offset[m.item]; ~tempo = 1.2 - (e.value); ~funkiness = f.value; ~reset_melody.value(); ~play_traditional.value()};

	//replay button
	d = Button.new(w, Rect(155, 410, 200, 30));
	d.string = "Replay last harmonization";
	d.action = {~replay.value()};
	w.front;
}
)
