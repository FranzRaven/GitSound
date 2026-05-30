// Inicialización del Servidor y Procesamiento Granular
// Corregido y optimizado

s.waitForBoot({
    // 1. Asignar buffer para el almacenamiento de audio en tiempo real
    // (5 segundos de audio mono a la tasa de muestreo actual)
    ~audioBuffer = Buffer.alloc(s, s.sampleRate * 5, 1);
    s.sync; // Esperar a que el buffer esté asignado en el servidor

    // 2. Definición del Sintetizador de Procesamiento Reactivo
    SynthDef(\ProcesadorGranular, {
        arg inBus = 0, outBus = 0, bufNum, grainSize = 0.08, pitchRate = 1.0;
        var inputSignal, recordPointer, grainEngine;

        // Captura de la entrada física (Micrófono)
        inputSignal = SoundIn.ar(inBus);

        // Grabación continua en el buffer circular
        recordPointer = RecordBuf.ar(inputSignal, bufNum, loop: 1);

        // Generador Granular leyendo el audio recién capturado
        grainEngine = TGrains.ar(
            numChannels: 2,
            trigger: Dust.kr(25),
            bufnum: bufNum,
            rate: pitchRate,
            // Corregido: el argumento en TGrains es 'centerPos', no 'pos'
            centerPos: LFNoise1.kr(0.5).range(0, BufDur.kr(bufNum)),
            dur: grainSize,
            pan: WhiteNoise.kr(0.6),
            amp: 0.8
        );

        // Mezcla de la señal granular estéreo con la señal directa mono (expandida a estéreo)
        Out.ar(outBus, grainEngine + (inputSignal * 0.2));
    }).add;
    
    s.sync; // Esperar a que la SynthDef se compile y cargue en el servidor

    // 3. Instanciar el procesador leyendo de la entrada 0 (Micrófono)
    // Corregido: se cambió el parámetro mal escrito y sin símbolo 'ufNum' por '\bufNum'
    ~procesador = Synth(\ProcesadorGranular, [\bufNum, ~audioBuffer]);

    "Sistema Experimental Inicializado Correctamente.".postln;
});
