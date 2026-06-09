<CsoundSynthesizer>
<CsOptions>
-odac ; Envía el audio directamente a la tarjeta de sonido en tiempo real
</CsOptions>
<CsInstruments>

sr = 48000
ksmps = 48
nchnls = 2
0dbfs = 1

instr KrellNotaTradicional
    ;; --- Parámetros de la entrada tradicional (Score) ---
    iStart     = p2       ; Inicio de la nota
    iDur       = p3       ; Duración total de la nota asignada en el Score
    iPitchMIDI = p4       ; Nota MIDI base ingresada desde el Score
    iAmp       = p5       ; Amplitud/Volumen base (0 a 1)

    ;; --- Lógica Krell Adaptada a la Nota ---
    kDurRate   randomh 0.5, 3.5, 1             ; Velocidad del ciclo del S&H
    kTrig      metro   kDurRate                ; Reloj que simula los re-disparos

    ;; Desviación aleatoria controlada (S&H) partiendo de la nota del Score
    kPitchOffset randomh -7, 7, kDurRate       ; Varía +/- 7 semitonos
    kTargetPitch =       iPitchMIDI + kPitchOffset

    ;; --- Conversiones de frecuencia paso a paso (Sintaxis Estricta) ---
    kFreq        cpsmidinn kTargetPitch        ; Convertimos la nota central a Hz

    ;; Pitch Drift analógico sutil para dar vida a los osciladores
    kDrift1    oscil   0.08, 0.2
    kDrift2    oscil   0.12, 0.35

    ;; EVITANDO EL ERROR DEL PARSER: No usamos paréntesis ni sumas directas complejas
    kPitchMod1 =       kTargetPitch
    kPitchMod1 =       kPitchMod1 + kDrift1

    kPitchMod2 =       kTargetPitch
    kPitchMod2 =       kPitchMod2 + kDrift2

    kFreqMod1  cpsmidinn kPitchMod1
    kFreqMod2  cpsmidinn kPitchMod2

    kFreq1     =       kFreqMod1 - kFreq
    kFreq2     =       kFreqMod2 - kFreq

    kOscFreq1  =       kFreq + kFreq1
    kOscFreq2  =       kFreq + kFreq2

    ;; --- Moduladores (Envolventes Exponenciales) ---
    ;; Envolvente principal de la nota (Mantiene vivo el instrumento lo que dure p3)
    kMainEnv   linseg  0, 0.01, 1, iDur - 0.05, 1, 0.04, 0

    ;; Envolvente interna "Krell"
    kAttack    randomh 0.05, 0.3, kDurRate
    kRelease   randomh 0.2, 0.8, kDurRate
    kEnvAna    madsr   i(kAttack), 0.1, 0.7, i(kRelease)

    ;; --- Fuentes de Audio (Arquitectura ARP 2600) ---
    iWaveSaw   =       0    ; Modo 0: Diente de sierra
    iWavePulse =       2    ; Modo 2: Onda de pulso/cuadrada
    kPW        =       0.5  ; Ciclo de trabajo (50% = onda cuadrada)

    aVCO1      vco2    0.25, kOscFreq1, iWaveSaw
    aVCO2      vco2    0.20, kOscFreq2, iWavePulse, kPW
    aNoise     pinkish 0.08                 ; Generador de ruido rosado

    ;; --- Mezclador Pre-Filtro con Saturación ---
    aNoiseMod  =       aNoise * kEnvAna

    aMixV1     =       aVCO1 * 0.5
    aMixV2     =       aVCO2 * 0.4
    aMixN      =       aNoiseMod * 0.3
    aMixer     =       aMixV1 + aMixV2 + aMixN

    ;; Aislamiento de ganancia antes de distorsionar
    aDrive     =       aMixer * 1.5
    iDistGain  =       0.3
    aSat       distort aDrive, iDistGain, 0      ; Saturación analógica

    ;; --- VCF (Filtro Moog Pasabajos) ---
    kModCutoff =       kEnvAna * 2000
    kBaseCut   =       kFreq * 1.3
    kCutCalc   =       kBaseCut + kModCutoff

    kMinLimit  =       40
    kMaxLimit  =       16000
    kCutoff    limit   kCutCalc, kMinLimit, kMaxLimit

    aFilter    moogladder aSat, kCutoff, 0.3 ; Filtro Moog

    ;; --- VCA Output Stage ---
    aGain      =       kEnvAna * kMainEnv * iAmp
    aOut       =       aFilter * aGain
               outs    aOut, aOut
endin

</CsInstruments>
<CsScore>
;; --- ENTRADA TRADICIONAL DE NOTAS (Score) ---
;; Estructura: i (Inst) | p2 (Inicio) | p3 (Duración) | p4 (Nota MIDI) | p5 (Amplitud)

; Frase 1: Notas largas donde el Krell modulará internamente varias veces
i "KrellNotaTradicional"   0.0   4.0   48   0.7
i "KrellNotaTradicional"   4.5   4.0   55   0.6
i "KrellNotaTradicional"   9.0   6.0   51   0.7

; Frase 2: Notas más cortas consecutivas
i "KrellNotaTradicional"  16.0   2.0   60   0.5
i "KrellNotaTradicional"  18.5   2.0   62   0.5
i "KrellNotaTradicional"  21.0   3.0   58   0.6

; Un acorde de prueba (Polifonía tradicional habilitada)
i "KrellNotaTradicional"  25.0   5.0   43   0.5
i "KrellNotaTradicional"  25.0   5.0   50   0.5
i "KrellNotaTradicional"  25.0   5.0   57   0.4

e
</CsScore>
</CsoundSynthesizer>
