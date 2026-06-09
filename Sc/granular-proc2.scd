s.boot; // Asegúrate de encender el servidor

(
// =====================================================================
// 1. ASIGNACIÓN DE MEMORIA (BUFFER)
// =====================================================================
~audioBuffer = Buffer.alloc(s, s.sampleRate * 5, 2);

// =====================================================================
// 2. MOTORES DE AUDIO (SynthDefs)
// =====================================================================

SynthDef(\grabador, { |bufnum|
    var entrada = SoundIn.ar([0, 1]);
    RecordBuf.ar(entrada, bufnum, loop: 0, doneAction: 2);
}).add;

SynthDef(\granuladorVisual, { |out = 0, bufnum, amp = 0.5, gate = 1,
    transp = 1, densidad = 20, foldLevel = 1, startPos = 0, endPos = 5|

    var sig, env, densidadTrigger, duracionGrano, posicionActual;

    env = EnvGen.kr(Env.asr(0.1, 1, 0.5), gate, doneAction: 2);
    densidadTrigger = Dust.kr(densidad);
    duracionGrano = 4 / densidad;

    posicionActual = TRand.kr(startPos, endPos, densidadTrigger);

    sig = TGrains.ar(
        numChannels: 2,
        trigger: densidadTrigger,
        bufnum: bufnum,
        rate: transp,
        centerPos: posicionActual,
        dur: duracionGrano,
        pan: WhiteNoise.kr(0.4),
        amp: amp
    );

    sig = (sig * foldLevel).fold(-0.7, 0.7);

    Out.ar(out, sig * env);
}).add;

// =====================================================================
// 3. INTERFAZ GRÁFICA INTERACTIVA (GUI)
// =====================================================================
Window.closeAll;

~ventana = Window("Granulador Sampler + Wavefolder", Rect(200, 100, 520, 480))
    .front
    .background_(Color.grey(0.12));

~ventana.view.decorator = FlowLayout(~ventana.view.bounds, 15@15, 10@10);

// --- CONTROLES DE ACCIÓN (BOTONES) ---

~btnGrabar = Button(~ventana, Rect(0, 0, 115, 40))
    .states_([
        ["● Grabar Vivo", Color.white, Color.red(0.6)],
        ["■ Guardar", Color.white, Color.grey(0.4)]
    ])
    .action_({ |btn|
        if(btn.value == 1) {
            "Grabando de la entrada de audio...".postln;
            ~grabandoSint = Synth(\grabador, [\bufnum, ~audioBuffer]);
        } {
            "Grabación finalizada.".postln;
            ~grabandoSint.free;

            ~tempPath = Platform.defaultTempDir +/+ "granulador_vivo.wav";
            ~audioBuffer.write(~tempPath, "wav", "int16", leaveOpen: false);
            s.sync;
            ~dibujarOnda.value(~tempPath);
        };
    });

~btnCargarArchivo = Button(~ventana, Rect(0, 0, 140, 40))
    .states_([
        ["📂 Cargar Archivo", Color.black, Color.new255(240, 200, 80)]
    ])
    .action_({
        Dialog.openPanel({ |path|
            "Cargando archivo: ".post; path.postln;

            ~audioBuffer.free;
            ~audioBuffer = Buffer.read(s, path, action: { |buf|
                "Archivo cargado con éxito en el Buffer.".postln;
                ~dibujarOnda.value(path);
            });
        }, {
            "Carga cancelada.".postln;
        });
    });

~btnProcesar = Button(~ventana, Rect(0, 0, 130, 40))
    .states_([
        ["▶ Granular", Color.black, Color.green(0.6)],
        ["■ Detener", Color.white, Color.red(0.6)]
    ])
    .action_({ |btn|
        if(btn.value == 1) {
            var seleccion, startSec, durSec, endSec;

            seleccion = ~vistaOnda.selection(0);

            startSec = seleccion[0] / ~audioBuffer.sampleRate;
            durSec = seleccion[1] / ~audioBuffer.sampleRate;
            endSec = startSec + durSec;

            if(durSec == 0) { startSec = 0; endSec = ~audioBuffer.duration; };

            ~granuladorSint = Synth(\granuladorVisual, [
                \bufnum, ~audioBuffer,
                \startPos, startSec,
                \endPos, endSec,
                \densidad, ~sldDensidad.value.linepts(0, 1, 5, 80),
                \transp, ~sldPitch.value.linepts(0, 1, 0.25, 4.0),
                \foldLevel, ~sldFold.value.linepts(0, 1, 1, 15)
            ]);
        } {
            ~granuladorSint.set(\gate, 0);
        };
    });

~ventana.view.decorator.nextLine;

// --- DISPLAY VISUAL DE LA ONDA (SOUNDFILEVIEW) ---
StaticText(~ventana, 490@20).string_("Selecciona el rango arrastrando el mouse sobre la onda:").stringColor_(Color.grey(0.8));

~vistaOnda = SoundFileView(~ventana, Rect(0, 0, 490, 140))
    .gridOn_(false)
    .timeCursorOn_(false)
    .elasticMode_(true)
    .background_(Color.grey(0.05))
    .waveColors_([Color.cyan(0.8), Color.magenta(0.6)])
    .selectionColor_(Color.white.alpha_(0.25));

~vistaOnda.mouseUpAction = { |view|
    if(~granuladorSint.notNil && ~granuladorSint.isRunning) {
        var sel = view.selection(0);
        var start = sel[0] / ~audioBuffer.sampleRate;
        var end = start + (sel[1] / ~audioBuffer.sampleRate);
        if(sel[1] > 0) {
            ~granuladorSint.set(\startPos, start, \endPos, end);
        };
    };
};

// =====================================================================
// CORRECCIÓN: FUNCIÓN DE DIBUJO UBICADA POST-CREACIÓN DE LA GUI
// =====================================================================
~dibujarOnda = { |path|
    var file = SoundFile.new;
    if(file.openRead(path)) {
        {
            ~vistaOnda.soundFile_(file);
            ~vistaOnda.read(0, file.numFrames, closeFile: true);
            ~vistaOnda.refresh;
        }.defer;
    } {
        "No se pudo abrir el archivo de audio para visualización.".postln;
    };
};

~ventana.view.decorator.nextLine;

// --- DESLIZADORES ---
StaticText(~ventana, 490@15).string_("Densidad de Granos").stringColor_(Color.white);
~sldDensidad = Slider(~ventana, 490@18).value_(0.3).action_({ |sl|
    if(~granuladorSint.notNil && ~granuladorSint.isRunning) {
        ~granuladorSint.set(\densidad, sl.value.linepts(0, 1, 5, 80));
    };
});

StaticText(~ventana, 490@15).string_("Pitch (Transposición)").stringColor_(Color.white);
~sldPitch = Slider(~ventana, 490@18).value_(0.5).action_({ |sl|
    if(~granuladorSint.notNil && ~granuladorSint.isRunning) {
        ~granuladorSint.set(\transp, sl.value.linepts(0, 1, 0.25, 4.0));
    };
});

StaticText(~ventana, 490@15).string_("Wavefolding (Plegado de Onda)").stringColor_(Color.white);
~sldFold = Slider(~ventana, 490@18).value_(0.0).action_({ |sl|
    if(~granuladorSint.notNil && ~granuladorSint.isRunning) {
        ~granuladorSint.set(\foldLevel, sl.value.linepts(0, 1, 1, 15));
    };
});

~ventana.onClose = {
    ~granuladorSint.free;
    ~audioBuffer.free;
    if(~tempPath.notNil) { File.delete(~tempPath) };
    "Recursos limpios.".postln;
};
)