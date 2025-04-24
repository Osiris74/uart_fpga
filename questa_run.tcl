# 1. Удаление предыдущих сессий
vlib work
vmap work work

# 2. Компиляция исходников
vlog -sv -work work ./src/*.sv ./testbench/tb.sv

# 3. Оптимизация с сохранением видимости
vopt work.tb -o tb_opt +acc

# 4. Запуск симуляции и сохранение WLF
vsim -gui -wlf wave.wlf tb_opt

# 5. Открыть окно Wave и добавить все сигналы
view wave
add wave -position insertpoint /*

# 6. Запустить симуляцию до конца
run -all


# To start manually: vsim -do questa_run.tcl