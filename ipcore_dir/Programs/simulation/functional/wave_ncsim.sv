

 
 
 




window new WaveWindow  -name  "Waves for BMG Example Design"
waveform  using  "Waves for BMG Example Design"

      waveform add -signals /Programs_tb/status
      waveform add -signals /Programs_tb/Programs_synth_inst/bmg_port/CLKA
      waveform add -signals /Programs_tb/Programs_synth_inst/bmg_port/ADDRA
      waveform add -signals /Programs_tb/Programs_synth_inst/bmg_port/DOUTA

console submit -using simulator -wait no "run"
