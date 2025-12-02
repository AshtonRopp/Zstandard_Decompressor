# Clear existing waves
delete wave *

# Add signals for tb_Frame_Header_Parser
add wave sim:/tb_Frame_Header_Parser/clk
add wave sim:/tb_Frame_Header_Parser/reset
add wave sim:/tb_Frame_Header_Parser/start

# DUT internal signals
add wave -radix hex sim:/tb_Frame_Header_Parser/dut/magic_number
add wave -radix hex sim:/tb_Frame_Header_Parser/dut/Frame_Header_Descriptor
add wave -radix hex sim:/tb_Frame_Header_Parser/dut/Window_Descriptor
add wave -radix hex sim:/tb_Frame_Header_Parser/dut/Dictionary_ID
add wave -radix hex sim:/tb_Frame_Header_Parser/dut/Frame_Content_Size

# Array / bus signal
add wave sim:/tb_Frame_Header_Parser/sizes

# Finished flag
add wave sim:/tb_Frame_Header_Parser/finished

# Run testbench
restart -f; run 200
