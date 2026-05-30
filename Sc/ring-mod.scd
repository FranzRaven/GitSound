  // 1. Definir el sintetizador de Modulación de Anillo
(
    SynthDef(\ringModulator, {
        arg carFreq = 440, modFreq = 100, amp = 0.3, gate = 1, out = 0;
        var car, mod, env, sig;

        // Envolvente básica para controlar el inicio y fin de la nota
        env = EnvGen.kr(Env.asr(0.05, 1, 0.1), gate, doneAction: 2);

        // Señal Portadora (Carrier)
        car = SinOsc.ar(carFreq, mul: 1.0);

        // Señal Moduladora (Modulator)
        mod = SinOsc.ar(modFreq, mul: 1.0);

        // Modulación de Anillo (Multiplicación de señales)
        sig = car * mod * env * amp;

        // Salida estéreo (duplicando el canal usando !2)
		Out.ar(out, sig ! 2);
}).add;)





    // 2. Probar el sonido en tiempo real
    // Ejecuta esta línea para crear el sintetizador:
    x = Synth(\ringModulator, [\carFreq, 500, \modFreq, 120, \amp, 0.25]);

    // 3. Modificar los parámetros dinámicamente
    // Cambia la moduladora para escuchar sonidos de campana metálica:
    x.set(\modFreq, 273);
    x.set(\carFreq, 600);

    // Cambia la moduladora a frecuencias muy bajas (LFO) para escuchar "batido" (las bandas laterales están tan cerca
  que causan interferencia):
    x.set(\modFreq, 2.8);
    x.set(\carFreq, 240);

    // 4. Detener el sonido (liberar el nodo en el servidor)
    x.set(\gate, 0); // O simplemente x.free;