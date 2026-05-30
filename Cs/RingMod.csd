    <CsoundSynthesizer>
    <CsOptions>
    ; Salida de audio en tiempo real
    -odac
    </CsOptions>
    <CsInstruments>

    sr = 48000
    ksmps = 32
    nchnls = 2
    0dbfs = 1

    ; Tabla de onda senoidal básica
    gisine ftgen 1, 0, 16384, 10, 1

    instr 1
      iAmp     = p4                      ; Amplitud general
      kCarFreq = p5                      ; Frecuencia de la Portadora (Carrier)
      kModFreq = p6                      ; Frecuencia de la Moduladora (Modulator)

      ; Generador de envolvente para evitar clics
      aEnv     linen iAmp, 0.05, p3, 0.05

      ; 1. Señal Portadora (Carrier)
      aCar     poscil 1, kCarFreq, gisine

      ; 2. Señal Moduladora (Modulator)
      aMod     poscil 1, kModFreq, gisine

      ; 3. Modulación de Anillo (Multiplicación directa)
      aRingMod = aCar * aMod * aEnv

      ; Enviar a los canales izquierdo y derecho (Stereo)
      outs aRingMod, aRingMod
    endin

    </CsInstruments>
    <CsScore>
    ; p1   p2   p3   p4(amp)  p5(fCar)  p6(fMod)
    ; Nota 1: Frecuencias armónicas (suena consonante, como acordes)
    i 1    0    2    0.5      400       200      ; Salida: 600Hz y 200Hz
    ; Nota 2: Frecuencias inarmónicas (sonido metálico / campana)
    i 1    +    2    0.5      440       123.4    ; Salida: 563.4Hz y 316.6Hz
    ; Nota 3: Efecto de trémolo rápido / sci-fi
    i 1    +    3    0.5      800       15       ; Salida: 815Hz y 785Hz (batido rápido)
    e
    </CsScore>
    </CsoundSynthesizer>
