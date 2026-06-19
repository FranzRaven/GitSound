s.boot;

(
// Define the SynthDef with a frequency argument
SynthDef(\oscSynth, { |out = 0, freq = 140, amp = 0.5|
    var sig = Saw.ar(freq) * amp;
    sig = sig ;
    Out.ar(out, sig!2);
}).add;
)
// Start the synth and store it in a variable
~mySynth = Synth(\oscSynth);

// Create the OSC listener
// It listens for messages sent to the address "/sc/freq"
(OSCdef(\changeFreq, { |msg|
    var receivedFreq;

    // msg[0] is the path ('/sc/freq')
    // msg[1] is the actual slider value
    receivedFreq = msg[1];

    // Update the synth
    ~mySynth.set(\freq, receivedFreq);

    // Print the raw array to the Post Window for debugging
    "Received OSC Message: ".post; msg.postln;
}, '/slider1');
)

// 1. Creamos un SynthDef simple con Sustain (Envelope con gate)
(
SynthDef(\synthTeclado, { |out = 0, freq = 440, gate = 1, amp = 0.7|
    var env, sig;
    // Un env con gate=1 se mantiene sonando hasta que gate recibe un 0
    env = EnvGen.kr(Env.adsr(0.01, 0.1, 0.5, 0.3), gate, doneAction: Done.freeSelf);
    sig = Saw.ar(freq) * env * amp;
    Out.ar(out, sig ! 2);
}).add;
)

// 2. Diccionario para guardar los synths activos usando la nota MIDI como clave
~notasActivas = Dictionary.new;

// 3. Receptor OSCdef
(
OSCdef(\receptorTeclado, { |msg|
    var ruta = msg[0];       // "/teclado"
    var notaMidi = msg[1];   // Número de nota (ej: 60)
    var velocidad = msg[2];  // 1 o 0
    var freq;

    // Convertimos la nota MIDI a frecuencias (Hz)
    freq = notaMidi.midicps;

    // Mensaje de depuración en el Post Window para verificar que entra la data
    ["Nota Recibida:", notaMidi, "Estado:", velocidad].postln;

    // EVALUAMOS SI ES NOTE ON O NOTE OFF
    if (velocidad == 1) {
        // --- NOTE ON ---
        // Si la nota ya estaba sonando por error, la liberamos antes
        if(~notasActivas[notaMidi].notNil) { ~notasActivas[notaMidi].set(\gate, 0) };

        // Encendemos el sintetizador y lo guardamos en el diccionario
        ~notasActivas[notaMidi] = Synth(\synthTeclado, [\freq, freq, \gate, 1]);
    } {
        // --- NOTE OFF ---
        // Si la nota existe en nuestro diccionario, le enviamos gate: 0 para que termine
        if(~notasActivas[notaMidi].notNil) {
            ~notasActivas[notaMidi].set(\gate, 0);
            ~notasActivas[notaMidi] = nil; // Sacamos la nota del registro activo
        };
    };

}, '/keyboard1'); // Asegúrate de que esta ruta coincida con el "address" en Open Stage Control
)


NetAddr.langPort;
NetAddr.localAddr;
NetAddr.localIP;
OSCdef.trace(false)