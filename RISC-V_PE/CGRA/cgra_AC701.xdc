## Clock input (100 MHz)
set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -name sys_clk -period 10.0 [get_ports clk]

## Reset button
set_property PACKAGE_PIN AB11 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

## Output LEDs (for done, branch_exec, etc.)
set_property PACKAGE_PIN V5 [get_ports done]
set_property IOSTANDARD LVCMOS33 [get_ports done]

set_property PACKAGE_PIN W5 [get_ports branch_exec[0]]
set_property IOSTANDARD LVCMOS33 [get_ports branch_exec[0]]

set_property PACKAGE_PIN Y5 [get_ports branch_exec[1]]
set_property IOSTANDARD LVCMOS33 [get_ports branch_exec[1]]

set_property PACKAGE_PIN AB5 [get_ports branch_exec[2]]
set_property IOSTANDARD LVCMOS33 [get_ports branch_exec[2]]

set_property PACKAGE_PIN AC5 [get_ports branch_exec[3]]
set_property IOSTANDARD LVCMOS33 [get_ports branch_exec[3]]

## Optional UART (for debugging)
set_property PACKAGE_PIN AB17 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

set_property PACKAGE_PIN AB18 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

## JA Header (result_out[7:0])
set_property PACKAGE_PIN AB13 [get_ports result_out[0]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[0]]

set_property PACKAGE_PIN AB14 [get_ports result_out[1]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[1]]

set_property PACKAGE_PIN AB15 [get_ports result_out[2]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[2]]

set_property PACKAGE_PIN AB16 [get_ports result_out[3]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[3]]

set_property PACKAGE_PIN AB17 [get_ports result_out[4]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[4]]

set_property PACKAGE_PIN AB18 [get_ports result_out[5]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[5]]

set_property PACKAGE_PIN AB19 [get_ports result_out[6]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[6]]

set_property PACKAGE_PIN AB20 [get_ports result_out[7]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[7]]

## JB Header (result_out[15:8])
set_property PACKAGE_PIN AC13 [get_ports result_out[8]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[8]]

set_property PACKAGE_PIN AC14 [get_ports result_out[9]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[9]]

set_property PACKAGE_PIN AC15 [get_ports result_out[10]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[10]]

set_property PACKAGE_PIN AC16 [get_ports result_out[11]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[11]]

set_property PACKAGE_PIN AC17 [get_ports result_out[12]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[12]]

set_property PACKAGE_PIN AC18 [get_ports result_out[13]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[13]]

set_property PACKAGE_PIN AC19 [get_ports result_out[14]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[14]]

set_property PACKAGE_PIN AC20 [get_ports result_out[15]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[15]]

## JC Header (result_out[23:16])
set_property PACKAGE_PIN AD13 [get_ports result_out[16]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[16]]

set_property PACKAGE_PIN AD14 [get_ports result_out[17]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[17]]

set_property PACKAGE_PIN AD15 [get_ports result_out[18]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[18]]

set_property PACKAGE_PIN AD16 [get_ports result_out[19]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[19]]

set_property PACKAGE_PIN AD17 [get_ports result_out[20]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[20]]

set_property PACKAGE_PIN AD18 [get_ports result_out[21]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[21]]

set_property PACKAGE_PIN AD19 [get_ports result_out[22]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[22]]

set_property PACKAGE_PIN AD20 [get_ports result_out[23]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[23]]

## JD Header (result_out[31:24])
set_property PACKAGE_PIN AE13 [get_ports result_out[24]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[24]]

set_property PACKAGE_PIN AE14 [get_ports result_out[25]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[25]]

set_property PACKAGE_PIN AE15 [get_ports result_out[26]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[26]]

set_property PACKAGE_PIN AE16 [get_ports result_out[27]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[27]]

set_property PACKAGE_PIN AE17 [get_ports result_out[28]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[28]]

set_property PACKAGE_PIN AE18 [get_ports result_out[29]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[29]]

set_property PACKAGE_PIN AE19 [get_ports result_out[30]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[30]]

set_property PACKAGE_PIN AE20 [get_ports result_out[31]]
set_property IOSTANDARD LVCMOS33 [get_ports result_out[31]]
