(
SynthDef(\arp2600, {
    arg freq = 220, cutoff = 1000, rq = 0.1, gate = 1;
    var vco1, vco2, noise, filter, env, vca, mixer;

    // Osciladores
    vco1 = Saw.ar(freq);
    vco2 = Pulse.ar(freq * 1.005, width: 0.5); // Un pelín desafinado
    noise = PinkNoise.ar(rq);

    // Mezclador básico pre-filtro
    mixer = (vco1 * 0.4) + (vco2 * 0.4) + noise;

    // Envolvente ADSR
    env = EnvGen.kr(Env.adsr(0.01, 0.3, 0.5, 1.0), gate, doneAction: 2);

    // El famoso Filtro ARP (usando una emulación Ladder)
    filter = MoogFF.ar(mixer, cutoff * env, gain: 2);

    // VCA
    vca = filter * env;

    Out.ar(0, vca ! 2);
}).add;
)

x = Synth(\arp2600)

x.set(\freq, 444)
x.set(\cutoff, 600)
x.set(\vco2, [\width, 120])
x.set(\rq, 9)
x.set(\gate, 0)

x.free