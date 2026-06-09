(
     s.waitForBoot({

         // --- 1. DUSG (Dual Universal Slope Generator) ---
         // The heart of the Serge. It can be an LFO, an Envelope, or an Oscillator.
         // We use Rise and Fall times to determine both frequency and timbre.
         Ndef(\dusg, {
             arg rise=0.005, fall=0.01, fmod=0;
             var freq = (1 / (rise + fall)) + fmod;
            var width = rise / (rise + fall);
            // VarSaw perfectly simulates the variable slope triangle/saw of the DUSG
           VarSaw.ar(freq.lag(0.1), 0, width.lag(0.1));
        });

        // --- 2. Triple Wave Multiplier ---
        // Serge's famous wavefolder. It adds harmonics by "folding" the wave back on itself.
        Ndef(\wavefolder, {
            var in = Ndef.ar(\dusg);
            var gain = \gain.kr(1).lag(0.2);
            var sig = in * (gain * 5); // Increase amplitude to force folding
            // Multi-stage folding (mimicking the Serge circuit)
          3.do { |i|
                sig = sig.fold2(1.0);
                sig = (sig * 1.2).sin; // Adding a bit of "soft" curvature
            };
            sig * 0.5;
        });

        // --- 3. SSG (Smooth and Stepped Generator) ---
        // Used for modulation. It generates a "stepped" (Sample & Hold)
        // and a "smooth" (Slew/Integrator) version of a signal.
        Ndef(\ssg, {
            arg rate=2, slew=0.2;
            var trig = Impulse.kr(rate);
            var noise = LFNoise1.kr(rate * 1.5);
            var stepped = Latch.kr(noise, trig);
            var smooth = stepped.lag(slew);
            [stepped, smooth]; // Output 0: Stepped, Output 1: Smooth
        });

        // --- 4. VCFQ (Variable Q Filter) / Low Pass Gate ---
        // Serge filters are very "pingable".
        // We'll simulate the "Vactrol" response with a slow lag on the gate.
        Ndef(\vcfq, {
            var sig = Ndef.ar(\wavefolder);
            var vactrol = \gate.kr(0).lag(\vactrolTime.kr(0.1));
            var cut = vactrol.linexp(0, 1, 80, 12000);
            var res = \res.kr(0.7);
            // RLPF with high resonance for that "liquid" Serge sound
            var filtered = RLPF.ar(sig, cut, (1 - res).clip(0.01, 1));

            filtered * vactrol;
        });

        // --- PATCHING: Connect SSG Smooth to DUSG Frequency ---
        Ndef(\dusg).map(\fmod, Ndef(\ssg));

        // Final Output
        Ndef(\vcfq).play;

        "Serge Patch Loaded. Use Ndef Mixer or code to play!".postln;
    });
    )

  // A short gate pulse with high resonance
  Ndef(\vcfq).set(\gate, 1, \res, 0.9, \vactrolTime, 0.05);
  SystemClock.sched(0.1, { Ndef(\vcfq).set(\gate, 0); nil });

 // Increase the Timbral Complexity (Wavefolding):

  // This is like turning the "Middle" or "Top" knob on a Wave Multiplier
  Ndef(\wavefolder).set(\gain, 4);

 // Change the DUSG Slope (Rise vs Fall):

  // Long rise, short fall = "Ramp" wave
  Ndef(\dusg).set(\rise, 0.08, \fall, 0.001);

 // Random Modulation (SSG):

  // Change the speed of the random movements
  Ndef(\ssg).set(\rate, 8, \slew, 0.1);