# Clear existing waves
delete wave *

# Add signals for tb_Block_Header_Parser
add wave sim:/tb_Block_Header_Parser/clk
add wave sim:/tb_Block_Header_Parser/reset

# DUT internal signals
add wave -radix hex sim:/tb_Block_Header_Parser/bhp/in_ready
add wave -radix hex sim:/tb_Block_Header_Parser/bhp/header_valid
add wave -radix hex sim:/tb_Block_Header_Parser/bhp/last_block
add wave -radix hex sim:/tb_Block_Header_Parser/bhp/block_type
add wave -radix hex sim:/tb_Block_Header_Parser/bhp/block_size
add wave -radix hex sim:/tb_Block_Header_Parser/bhp/raw_header
add wave -radix hex sim:/tb_Block_Header_Parser/bhp/little_endian_header

# Run testbench
restart -f; run 200
