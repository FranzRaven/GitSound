// 1. INICIAR EL SERVIDOR Y CONFIGURAR EL RECEPTOR OSC
s.boot;

(
// Asegurar que SuperCollider escucha en el puerto correcto (por defecto 57120)
// Nota: Configura tu Open Stage Control para enviar datos a este puerto.
thisProcess.openUDPPort(57120);

// 2. DEFINICIÓN DEL SINTETIZADOR (Estilo Buchla Complex Oscillator + Wavefolder)
SynthDef(\buchlaSynth, {
    arg out = 0, amp = 0.2, gate = 1,
        carrierFreq = 110, modFreqRatio = 2, modIndex = 0,
        foldLevel = 1, attack = 0.05, release = 0.4;

    var carrier, modulator, wavefolder, env, modFreq;

    // Relación de frecuencia del modulador (típico de Buchla)
    modFreq = carrierFreq * modFreqRatio;

    // Oscilador Modulador (Genera la FM lineal)
    modulator = SinOsc.ar(modFreq) * modFreq * modIndex;

    // Oscilador Principal (Carrier) con modulación de frecuencia
    carrier = SinOsc.ar(carrierFreq + modulator);

    // --- CIRCUITO WAVEFOLDER (Estilo Serge / Buchla) ---
    // Multiplicamos la señal y la hacemos "plegarse" sobre sí misma usando funciones trigonométricas/clipping
    wavefolder = (carrier * foldLevel).fold2(0.8);
    // Un toque extra de distorsión armónica suave para emular los diodos analógicos
    wavefolder = (wavefolder * 1.5).sin;

    // Envolvente principal (Exponencial para emular un Low Pass Gate - LPG)
    env = EnvGen.kr(Env.asr(attack, 1, release, \exponential), gate, doneAction: 2);

    // Salida estéreo con paneo central suave
    Out.ar(out, Pan2.ar(wavefolder * env * amp, 0));
}).add;
)

// 3. MAPEO Y RECEPCIÓN DE MENSAJES OSC (Open Stage Control)
(
~mySynth = nil;

// Activar el sintetizador al presionar un botón/pad
OSCdef(\synthOn, { |msg|
    var velocity = msg[1];
    if (velocity > 0) {
        // Si ya hay un synth sonando, lo liberamos primero
        if(~mySynth.notNil) { ~mySynth.set(\gate, 0) };

        ~mySynth = Synth(\buchlaSynth, [
            \carrierFreq, velocity.linexp(0, 1, 60, 400), // mapea el valor a Hz
            \gate, 1
        ]);
    } {
        if(~mySynth.notNil) { ~mySynth.set(\gate, 0); ~mySynth = nil; };
    };
}, '/synth/gate');

// Controlar la Frecuencia Principal
OSCdef(\setFreq, { |msg|
    var val = msg[1]; // Espera un valor flotante entre 0.0 y 1.0
    var hz = val.linexp(0, 1, 40, 500); // Mapeo exponencial para Pitch
    if(~mySynth.notNil) { ~mySynth.set(\carrierFreq, hz) };
}, '/synth/freq');

// Controlar el Índice de Modulación (FM Amount)
OSCdef(\setModIndex, { |msg|
    var val = msg[1]; // 0.0 a 1.0
    var index = val.linlin(0, 1, 0, 8); // Cantidad de FM
    if(~mySynth.notNil) { ~mySynth.set(\modIndex, index) };
}, '/synth/modindex');

// Controlar el Ratio del Modulador (Armónicos West Coast)
OSCdef(\setModRatio, { |msg|
    var val = msg[1];
    var ratio = val.linlin(0, 1, 0.5, 5.0).round(0.25); // Saltos musicales de ratio
    if(~mySynth.notNil) { ~mySynth.set(\modFreqRatio, ratio) };
}, '/synth/modratio');

// Controlar el Wavefolder (Pliegue de onda / Timbre)
OSCdef(\setFold, { |msg|
    var val = msg[1];
    var fold = val.linlin(0, 1, 1, 15); // Nivel de pliegues armónicos
    if(~mySynth.notNil) { ~mySynth.set(\foldLevel, fold) };
}, '/synth/fold');

// Controlar el Release (Decay del Low Pass Gate simulado)
OSCdef(\setRelease, { |msg|
    var val = msg[1];
    var rel = val.linexp(0, 1, 0.05, 3.0);
    if(~mySynth.notNil) { ~mySynth.set(\release, rel) };
}, '/synth/release');
)