ca65 dos-c64.asm -t none
ld65 dos-c64.o -t none -o doswedge
# compare original dow wedge with new dos wedge
xxd orig-wedge > orig.hex
xxd doswedge > new.hex
diff orig.hex new.hex
