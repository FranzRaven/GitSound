s.boot; // Asegúrate de que el servidor esté corriendo

(
SynthDef(\easel, {
    arg out = 0, freq = 110, amp = 0.5, pan = 0,
        // Controles Buchla
        modFreqRatio = 3.5, modIndex = 50, // FM
        foldLevel = 0.2,                  // Wavefolder (0 a 1)
        lpgCombo = 0.5,                   // 0 = solo Filtro, 1 = solo Amp, 0.5 = Ambos (LPG clasico)
        lpgCutoff = 1000, lpgRes = 0.1,
        // S&H y Ruido
        shRate = 8, shSubtle = 0.1,
        // Envolvente
        atk = 0.005, rel = 0.6;

    var car, mod, env, fold, sAndH, noise, lpgOut, sig;

    // 1. Ruido Blanco y Sample & Hold (Afecta sutilmente a la frecuencia del portador)
    noise = WhiteNoise.ar();
    sAndH = Latch.kr(noise, Impulse.kr(shRate)) * shSubtle;

    // Aplicar S&H a la frecuencia fundamental
    freq = freq * (1 + sAndH);

    // 2. Modulador FM (Inspirado en el Buchla Modulation Oscillator)
    mod = SinOsc.ar(freq * modFreqRatio) * modIndex;

    // 3. Oscilador Portador (Generador de Timbre Complejo)
    car = SinOsc.ar(freq + mod);

    // 4. Wavefolder (Sección "Timbre" del Easel)
    // Usamos Shaper o combinaciones de funciones hiperbólicas para simular el plegado de onda
    fold = (car * (1 + (foldLevel * 8))).tanh; // Saturación inicial
    fold = (fold * 1.5).sin;                   // Plegado de onda (wavefolding)

    // Mezcla entre la onda pura y la onda plegada
    sig = XFade2.ar(car, fold, foldLevel * 2 - 1);

    // 5. Envolvente del Low Pass Gate (LPG)
    // El LPG clásico tiene un "vactrol" que genera una caída orgánica y un sutil "decay tail"
    env = EnvGen.kr(Env.perc(atk, rel, curve: -4), doneAction: 2);

    // 6. Simulación del Low Pass Gate (Combo de Filtro y Amplitud)
    // El control lpgCombo balancea entre comportamiento de Filtro Pasabajos y Amplificador
    lpgOut = MoogFF.ar(sig, lpgCutoff * env, lpgRes); // Filtro dinámico por envolvente
    sig = XFade2.ar(lpgOut, sig * env, lpgCombo * 2 - 1);

    // Ajuste final de ganancia y paneo
    sig = Balance2.ar(sig, sig, pan, amp * env);

    Out.ar(out, sig);
}).add;

// 2. Bus y Synth de Reverb (Efecto Global de Resorte/Espacial)
~reverbBus = Bus.audio(s, 2);

SynthDef(\easelReverb, {
    arg in, out = 0, mix = 0.4, room = 0.8, damp = 0.5;
    var sig, rev;
    sig = In.ar(in, 2);
    // Usamos FreeVerb para el vivo, o puedes cambiar a JPverb si buscas algo más denso
    rev = FreeVerb.ar(sig, mix, room, damp);
    Out.ar(out, rev);
}).add;
)

// Activar el procesador de Reverb global
~fx = Synth(\easelReverb, [\in, ~reverbBus, \out, 0, \mix, 0.5, \room, 0.85], target: s, addAction: \addAfter);

Scale.directory;
(
p = Pbindef( \easel,
    \instrument, \easel,
    \out, ~reverbBus, // Enviamos todo al Reverb

    \scale, Scale.whole,
    \degree, Pseq([0, 2, 3, 4, 7, 6, 4, 2], inf),
    \octave, Pwrand([4, 5, 3], [0.6, 0.3, 0.1], inf),

    // Ritmo Buchla: Sincopado e impredecible
    //\dur, Pbjorklund2(3, 8, inf) * 0.25,
    \dur, Pseq([0.75, 0.75, 0.5], inf) * 0.9,
    // --- CONTROLES EN VIVO (Modifica estos valores mientras corre) ---
    \atk, 0.002,
    \rel, Pwhite(0.1, 0.7, inf),      // Caída orgánica variable (Vactrol decay)

    \modFreqRatio, 0.5,               // Relación armónica de la FM
    \modIndex, Pseq([10, 200, 500, 50], inf), // Cantidad de modulación por paso

    \foldLevel, Pseq([0.1, 0.5, 0.9], inf), // Nivel de deformación de la onda (Timbre)

    \lpgCombo, 0.2,                   // Más cerca de 0 es más "perc_filtro", cerca de 1 es más "abierto"
    \lpgCutoff, 1200,
    \lpgRes, 1.5,                     // Resonancia del LPG

    // Sección Sample & Hold (Modula la afinación sutilmente en cada nota)
    \shRate, Pwhite(5, 20, inf),
    \shSubtle, 0.04,                  // Si subes esto, sonará muy experimental/atonal

    \amp, Pwhite(0.3, 0.6, inf),
    \pan, Pwhite(-0.6, 0.6, inf)
)
)

~p = p.play;
~p.stop;
~fx.set(\room, 0.7)
Pbindef(\easel, \dur, Pseq([0.19, 0.716, 0.6], inf) * 0.2742 );

Pbindef(\easel, \modFreqRatio, 0.67)
Pbindef(\easel, \modIndex, Pseq([20, 334, 223], inf) )
Pbindef (\easel, \scale, Scale.chromatic)