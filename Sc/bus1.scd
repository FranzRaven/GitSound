
// 1. Inicializar ProxySpace
p = ProxySpace.push(s);

// 2. Cuantización (Crucial para Live Coding)
// Esto hace que cualquier cambio de código espere al siguiente pulso del reloj
p.quant = 1.0;

// VCO 1: Oscilador de onda de sierra con un vibrato lento incorporado
~vco1 = { |freq = 60, detune = 0.5| Saw.ar([freq, freq + detune]) };

// VCO 2: Onda de pulso
~vco2 = { |freq = 120, width = 0.5, fktr = 1.5, amp = 1| Pulse.ar([freq, freq*fktr], width) * amp };
~lfo1 = { |speed = 1, min = 200, max = 2000| SinOsc.kr(speed).exprange(min, max) };

~vcf = { |rq = 0.1| RLPF.ar(~vco1.ar + ~vco2.ar, ~lfo1.kr, rq) };

~vca = { |amp = 0.5| ~vcf.ar * amp };

~vca.play; // <--- Solo el VCA se escucha directamente
~vca.stop;
~vco1.set( \freq, 289,  \detune, 0.228)
~vco2.set(\freq, 234, \width, 0.4, \fktr, 2, \amp, 0.9)
~vcf.set(\rq, 0.9)
~lfo1.set(\speed, 0.224, \min, 23, \max, 940)


