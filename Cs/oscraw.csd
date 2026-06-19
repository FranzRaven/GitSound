<CsoundSynthesizer>
<CsInstruments>
sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1

; 1. Start the OSC listener thread on port 9000
gi_osc oscinit 9000

instr 1
  ; 2. Define data types ("f" for float) and the target address path
  k_amp init 0
  k_new OSClisten gi_osc, "/osc/path", "f", k_amp
  
  ; Only change amplitude if a new message was received
  if k_new == 1 then
      printks "Received OSC value: %f\n", 0, k_amp
  endif

  ; Audio generation using the received k_amp
  a_sig poscil k_amp, 440
  outs a_sig, a_sig
endin
</CsInstruments>
<CsScore>
i 1 0 3600
</CsScore>
</CsoundSynthesizer>
