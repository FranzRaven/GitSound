s.boot;

(
// 1. EL MOTOR DE SÍNTESIS: "The West Coast Trash Generator"
SynthDef(\westCoastTrash, {
    arg out=0, amp=0.25, freq=60,
        modRatio=1.414, modIndex=2,       // FM inestable
        foldLevel=2, waveShape=0.01,      // Wavefolding + Bit-destruction
        vactrolSlew=0.08, noiseMod=0.1,    // Inestabilidad de componentes
        gate=1, pan=0;

    var carrier, modulator, modFreq, wavefolder, env, noise, vactrolEnv;

    // Ruido rosa analógico interno (inestabilidad térmica de pitch)
    noise = PinkNoise.kr(1) * noiseMod * freq;
    freq = (freq + noise).clip(20, 5000);
    modFreq = freq * modRatio;

    // Modulador FM caótico
    modulator = SinOsc.ar(modFreq) * modFreq * modIndex;

    // Oscilador base (Triangular)
    carrier = LFTri.ar(freq + modulator);

    // --- SECCIÓN DE DAÑO TIMBRAL (Wavefolder + Shaper sucio) ---
    wavefolder = (carrier * foldLevel).fold2(0.7);
    wavefolder = (wavefolder * 2).sin;

    // "Shitty factor": Cuantización extrema de amplitud
    wavefolder = wavefolder.round(waveShape.linexp(0, 1, 0.001, 0.4));

    // --- EMULACIÓN DE VACTROL (Low Pass Gate con lag/slew) ---
    vactrolEnv = EnvGen.kr(Env.asr(0.01, 1, 0.1), gate);
    vactrolEnv = Lag.kr(vactrolEnv, vactrolSlew);

    // Filtro/Amplitud combinado (LPG West Coast)
    wavefolder = LPF.ar(wavefolder, vactrolEnv.linexp(0, 1, 60, 10000));
    wavefolder = wavefolder * vactrolEnv;

    Out.ar(out, Pan2.ar(wavefolder * amp, pan));
}).add;

// 2. ENTORNO DE SECUENCIAS Y VARIABLES GLOBALES
~clock = TempoClock(2.0);
~currentNotes = List[36, 48, 51, 55, 58]; // Secuencia inicial por defecto
~isPlaying = false;
~freeRun = 0; // 0 = Con reloj, 1 = Clockless caótico

// Valores iniciales de los parámetros
~modIndexVal = 3;
~modRatioVal = 1.5;
~foldLevelVal = 4;
~shapeVal = 0.01;
~slewVal = 0.05;
~bpmVal = 120;

~sequenceTask = Task({
    var step = 0;
    loop {
        if (~freeRun == 0) {
            // MODO CON CLOCK
            if (~currentNotes.size > 0 and: { 0.8.coin }) {
                var midiNote = ~currentNotes.wrapAt(step);
                if (0.3.coin) { midiNote = midiNote + [ -0.5, 0.5, 12, -12 ].choose }; // glitches microtonales

                s.makeBundle(0.02, {
                    var synth = Synth(\westCoastTrash, [
                        \freq, midiNote.midicps,
                        \modRatio, ~modRatioVal,
                        \modIndex, ~modIndexVal,
                        \foldLevel, ~foldLevelVal,
                        \waveShape, ~shapeVal,
                        \vactrolSlew, ~slewVal
                    ]);
                    SystemClock.sched(rrand(0.05, 0.25), { synth.set(\gate, 0); nil });
                });
            };
            step = step + 1;
            (~clock.beatDur / 2).wait;
        } {
            // MODO SIN CLOCK (Free-run / Drone-Arp asíncrono)
            if (~currentNotes.size > 0) {
                var midiNote = ~currentNotes.choose;
                s.makeBundle(0.01, {
                    var synth = Synth(\westCoastTrash, [
                        \freq, (midiNote + rrand(-0.2, 0.2)).midicps,
                        \modRatio, rrand(0.5, 4.0), // En este modo el ratio se vuelve inestable por evento
                        \modIndex, ~modIndexVal,
                        \foldLevel, ~foldLevelVal,
                        \waveShape, ~shapeVal,
                        \vactrolSlew, rrand(0.1, ~slewVal.max(0.2))
                    ]);
                    SystemClock.sched(rrand(0.02, 0.6), { synth.set(\gate, 0); nil });
                });
            };
            rrand(0.04, 0.35).wait; // Tiempos de disparo orgánicos y amorfos
        };
    };
});

// 3. CREACIÓN DE LA INTERFAZ GRÁFICA (GUI)
Window.closeAll; // Cerrar ventanas previas si existen

~win = Window("West Coast Shitty Synthesizer", Rect(200, 200, 450, 520))
    .front
    .background_(Color.fromHexString("#1a1a1a"));

~win.view.decorator = FlowLayout(~win.view.bounds, 15@15, 15@15);

// --- CONTROLES DE SECUENCIA Y TIEMPO ---
StaticText(~win, 420@25).string_("CONTROLES DE SECUENCIA").stringColor_(Color.white).font_(Font("Helvetica", 14, true));

// Botón Start/Stop
~btnPlay = Button(~win, 130@40)
    .states_([["START", Color.black, Color.fromHexString("#4caf50")], ["STOP", Color.white, Color.fromHexString("#f44336")]])
    .action_({ |b|
        if (b.value == 1) {
            ~isPlaying = true;
            ~sequenceTask.start(~clock);
        } {
            ~isPlaying = false;
            ~sequenceTask.stop;
        };
    });

// Botón Modo de Reloj
~btnClock = Button(~win, 130@40)
    .states_([["CON CLOCK", Color.white, Color.fromHexString("#2196f3")], ["CLOCKLESS (CAOS)", Color.black, Color.fromHexString("#ff9800")]])
    .action_({ |b|
        ~freeRun = b.value;
    });

// Slider BPM
EZSlider(~win, 420@22, "BPM", ControlSpec(40, 240, \lin, 1, 120), { |sl|
    ~clock.tempo = sl.value / 60;
}, 120, labelWidth: 80, numberWidth: 40).labelView.stringColor_(Color.white);

// Lanzador de Secuencias (Menú Desplegable)
StaticText(~win, 100@25).string_("Cambiar Banco:").stringColor_(Color.white);
~menuPattern = PopUpMenu(~win, 305@25)
    .items_([
        "0. Buchla Low Drone Sub (Oscuro)",
        "1. Alien Pentatonic (Ondas del espacio)",
        "2. Octave Glitch Jumps (Saltos caóticos)",
        "3. Microtonal Dissonant Melt (Denso/Roto)"
    ])
    .action_({ |menu|
        ~currentNotes = switch(menu.value,
            0, { List[36, 48, 51, 55, 58] },
            1, { List[60, 62, 65, 67, 69] },
            2, { List[48, 60, 72, 75, 77] },
            3, { List[40, 41, 43, 60, 61] }
        );
    });

// Separador visual
UserView(~win, 420@2).background_(Color.gray(0.4));

// --- CONTROLES DEL TIMBRE SÓNICO ---
StaticText(~win, 420@25).string_("DESTRUCCIÓN ANALÓGICA (WEST COAST)").stringColor_(Color.white).font_(Font("Helvetica", 14, true));

// Slider Índice de FM
EZSlider(~win, 420@25, "FM INDEX", ControlSpec(0, 20, \lin, 0.1, 3), { |sl|
    ~modIndexVal = sl.value;
}, ~modIndexVal, labelWidth: 100).labelView.stringColor_(Color.white);

// Slider Ratio de FM
EZSlider(~win, 420@25, "FM RATIO", ControlSpec(0.25, 6.0, \lin, 0.01, 1.5), { |sl|
    ~modRatioVal = sl.value;
}, ~modRatioVal, labelWidth: 100).labelView.stringColor_(Color.white);

// Slider Wavefolder
EZSlider(~win, 420@25, "WAVEFOLDER", ControlSpec(1, 30, \lin, 0.1, 4), { |sl|
    ~foldLevelVal = sl.value;
}, ~foldLevelVal, labelWidth: 100).labelView.stringColor_(Color.white);

// Slider Shitty Shape (Bitcrush/Destrucción de forma de onda)
EZSlider(~win, 420@25, "SHITTY SHAPE", ControlSpec(0.0, 1.0, \lin, 0.01, 0.01), { |sl|
    ~shapeVal = sl.value;
}, ~shapeVal, labelWidth: 100).labelView.stringColor_(Color.white);

// Slider Vactrol Slew (LPG)
EZSlider(~win, 420@25, "VACTROL SLEW", ControlSpec(0.005, 1.5, \exp, 0.001, 0.05), { |sl|
    ~slewVal = sl.value;
}, ~slewVal, labelWidth: 100).labelView.stringColor_(Color.white);

// Limpieza automática al cerrar la ventana
~win.onClose = {
    ~sequenceTask.stop;
    ~isPlaying = false;
    "Motor detenido y ventana cerrada.".postln;
};
)