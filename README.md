# ZORNS
ZORNS is patching sandbox inspired by ZOIA. It offers you a collection of I/O, GENERATOR, an LOGIC modules which can be used to trigger Midi notes and send control messages. By now ZORNS interfaces with Midi via USB, the internal engine, Softcut, and CROW.

## MODULES
Modules are building blocks which can generate and process signals. Signals are routed into a module's inputs from any output. A module represents its inputs and outputs via single grid cells. Modules are always designed horizontally, all input and output cells are adjacent.

## CONNECTIONS
Connections are created by pressing one input and one output in any order. Each input can only hold one connection, an output can be connected to any number of inputs. Each connection is associated with  a strength value which is by default 1. The passing signal is multiplied with the strength value.

## SIGNAL LEVELS

signal levels are between [0,1], CV signals can be bipolar [-1,1]

## MODULES
Modules are generted by holding an empty cell, immediatly the selection menu pops up, allowing you to browse modules via their superordinate categories.

### I/O
- clock_in \[start\]\[stop\]\[4ppq\]
- note_out \[gate\]\[pitch\]\[velocity\]\[channel\]
- cc_out
- engine
- softcut
- crow_out
- crow_in

### GENERATORS
- lfo \[freq\]\[amp\]\[out\]
- s&h \[signal\]\[gate\]\[out\]
- vca \[signal\]\[amp\]\[out\]
- scale \[signal\]\[out\]
- sqncr \[gate\]\[step1\]\[...\]\[step8\]\[out\]\[gate\]

### LOGIC
- and \[A\]\[B\]\[A&B\]
- or \[A\]\[B\]\[A|B\]

- VCA
- LFO
- CLOCK
- CLOCK_DIV
- SEQ
- SEL
- B_GATE
- QUANTIZER
- NOTE_OUT

## INTERACTIONS
Hold any cell to select an:
- input
- value
- output

Hold an input and outut cell to edit (change strength, delete) the selected connection.
