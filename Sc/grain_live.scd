// Inicialización del Servidor y Procesamiento Granular
s.boot;
(
Routine({
// 1. Asignar buffer para el almacenamiento de audio en tiempo real
~audioBuffer = Buffer.alloc(s, s.sampleRate * 5, 1);
s.sync;
// 2. Definición del Sintetizador de Procesamiento Reactivo
SynthDef(\Procesadoranular, {
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
centerPos: LFNoise1.kr(0.5).range(0, BufDur.kr(bufNum)),
dur: grainSize,
pan: WhiteNoise.kr(0.6),
amp: 0.8
);
Out.ar(outBus, grainEngine + (inputSignal * 0.2));
}).add;
s.sync;
// 3. Instanciar el procesador leyendo de la entrada 0 (Micrófono)
~procesador = Synth(\ProcesadorGranular, [ \bufNum, ~audioBuffer]);
"Sistema Experimental Inicializado Correctamente.".postln;
}).play;
)

