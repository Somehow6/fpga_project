onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib rom_1024x10b_opt

do {wave.do}

view wave
view structure
view signals

do {rom_1024x10b.udo}

run -all

quit -force
