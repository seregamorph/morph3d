:The source is written in TASM Ideal Mode using TASM 3.0 and TLINK 5.0

@echo off

tasm morph3d
tasm morphsub
tasm 3dtrans
tasm sintab
tlink morph3d morphsub 3dtrans sintab /t
