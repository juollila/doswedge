Introduction
============

The DOS Wedge is a tool which make disk operations in Commodore Basic easier by introducing several keyword shortcuts.

This repository contains commented disassemblies of original DOS wedges of VIC-20 and Commodore 64.

C64 DOS Wedge (DOS 5.1)
=======================

The C64 DOS Wedge supports the following commands:
```
/filename   Load a BASIC program into RAM
%filename   Load a machine language program into RAM
↑filename   Load a BASIC program into RAM and then automatically run it
←filename   Save a BASIC program to disk
@           Display (and clear) the disk drive status
@$          Display the disk directory without overwriting the BASIC program in memory
@command    Execute a disk drive command (e.g. S0:filename, V0:, I0:)
@Q          Deactivate the DOS Wedge
```

VIC-20 DOS Wedge
================

The VIC-20 DOS Wedge supports the following commands:
```
/filename   Load a BASIC program into RAM
@           Display (and clear) the disk drive status,
@command    Execute a disk drive command (e.g. S0:filename, V0:, I0:)
@$          Display the disk directory without overwriting the BASIC program in memory

Note: > can be used instead of @.
``` 
