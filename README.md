# BabyBaby
VHDL Implementation of the Manchester Small Scale experiminetal Computer.

This is a VHDL implementation of the Manchester Small scale Expermintal Computer. 

The code is designed to run on a Digilent Nexysy II board with a VGA display. 

For a Basic Implementation only 3 switches and 2 push buttones are needed. The switchs are used as follows:-

Halt/Run
KC - Single Step
KCC - Clear the Control Store 

and the Push Buttons are used to select the Display. 

As the Nexys II board has 8 Slide Switchs and 4 Push Buttons it can easily host a working Baby Baby
by amending the UCF constraints file. 

For a full implemnetation additions switchs are required. My prototype used 3 x MCP23S17 SPI chips to interface these switchs.

Appart from the SPI interface which is Copyright but freely re-usable, the code is Public Domain.
