(SynthDef(\pan1,
{
    Mix.fill(10, {
        var freq = exprand(130, 1160.3);
        Pan2.ar(SinOsc.ar(Gendy3.ar(6.rand, 6.rand, SinOsc.kr(0.1, 0, 0.49, 0.51), SinOsc.kr(0.13, 0, 0.49, 0.51), freq, SinOsc.kr(0.17, 0, 0.0049, 0.0051), SinOsc.kr(0.19, 0, 0.0049, 0.0051), 12, 12, 200, 400), 0, 0.1), 1.0.rand2)
    });
}).add
)

// Gendy1 into Gendy2 into Gendy3...with cartoon side effects
(
SynthDef(\pan2,
{ Pan2.ar(
    Gendy3.ar(1, 2, freq: Gendy2.ar(maxfreq: Gendy1.kr(5, 4, 0.3, 0.7, 0.1, MouseY.kr(0.1, 10), 1.0, 1.0, 5, 5, 25, 26), minfreq: 24, knum: MouseX.kr(1, 13), mul: 150, add: 200), durscale: 0.01, ampscale: 0.01, mul: 0.1),
    0.0)
}).add
)

// play me
{ Pan2.ar(RLPF.ar(Gendy3.ar(1, 3, freq: MouseX.kr(100, 1000), durscale: 0.0, ampscale: MouseY.kr(0.0, 0.1), initCPs: 7, knum: MouseY.kr(7, 2)), 500, 0.3, 0.2), 0.0) }.play

// used as an LFO
(
{ Pan2.ar(SinOsc.ar(Gendy3.kr(2, 5, SinOsc.kr(0.1, 0, 0.49, 0.51), SinOsc.kr(0.13, 0, 0.49, 0.51), 0.34, SinOsc.kr(0.17, 0, 0.49, 0.51), SinOsc.kr(0.19, 0, 0.49, 0.51), 10, 10, mul: 50, add: 350), 0, 0.3), 0.0) }.play
)

~pan2 = Synth(\pan2)
~pan2.set(\durscale, 0.123)

~pan1= Synth(\pan1)
~pan1.set(\freq, exprand(50, 1500))