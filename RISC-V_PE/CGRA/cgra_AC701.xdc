## Clock input (100 MHz)
set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -name sys_clk -period 10.0 [get_ports clk]

## Reset button
set_property PACKAGE_PIN AB11 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

## Status output: done
set_property PACKAGE_PIN V5 [get_ports done]
set_property IOSTANDARD LVCMOS33 [get_ports done]

## Branch_exec[3:0] to LEDs
set_property PACKAGE_PIN W5 [get_ports branch_exec[0]]
set_property IOSTANDARD LVCMOS33 [get_ports branch_exec[0]]

set_property PACKAGE_PIN Y5 [get_ports branch_exec[1]]
set_property IOSTANDARD LVCMOS33 [get_ports branch_exec[1]]

set_property PACKAGE_PIN AB5 [get_ports branch_exec[2]]
set_property IOSTANDARD LVCMOS33 [get_ports branch_exec[2]]

set_property PACKAGE_PIN AC5 [get_ports branch_exec[3]]
set_property IOSTANDARD LVCMOS33 [get_ports branch_exec[3]]

## UART (optional)
set_property PACKAGE_PIN AB17 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

set_property PACKAGE_PIN AB18 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

## result_out[127:0] mapped to PMOD headers JA–JD

# JA Header (result_out[0] to result_out[31])
foreach i {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31} {
    set_property PACKAGE_PIN [lindex {AB13 AB14 AB15 AB16 AB17 AB18 AB19 AB20 AC13 AC14 AC15 AC16 AC17 AC18 AC19 AC20 AD13 AD14 AD15 AD16 AD17 AD18 AD19 AD20 AE13 AE14 AE15 AE16 AE17 AE18 AE19 AE20} $i] [get_ports result_out[$i]]
    set_property IOSTANDARD LVCMOS33 [get_ports result_out[$i]]
}

# JB Header (result_out[32] to result_out[63])
foreach i {32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63} {
    set_property PACKAGE_PIN [lindex {AF13 AF14 AF15 AF16 AF17 AF18 AF19 AF20 AG13 AG14 AG15 AG16 AG17 AG18 AG19 AG20 AH13 AH14 AH15 AH16 AH17 AH18 AH19 AH20 AJ13 AJ14 AJ15 AJ16 AJ17 AJ18 AJ19 AJ20} [expr $i - 32]] [get_ports result_out[$i]]
    set_property IOSTANDARD LVCMOS33 [get_ports result_out[$i]]
}

# JC Header (result_out[64] to result_out[95])
foreach i {64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95} {
    set_property PACKAGE_PIN [lindex {AK13 AK14 AK15 AK16 AK17 AK18 AK19 AK20 AL13 AL14 AL15 AL16 AL17 AL18 AL19 AL20 AM13 AM14 AM15 AM16 AM17 AM18 AM19 AM20 AN13 AN14 AN15 AN16 AN17 AN18 AN19 AN20} [expr $i - 64]] [get_ports result_out[$i]]
    set_property IOSTANDARD LVCMOS33 [get_ports result_out[$i]]
}

# JD Header (result_out[96] to result_out[127])
foreach i {96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127} {
    set_property PACKAGE_PIN [lindex {AP13 AP14 AP15 AP16 AP17 AP18 AP19 AP20 AR13 AR14 AR15 AR16 AR17 AR18 AR19 AR20 AT13 AT14 AT15 AT16 AT17 AT18 AT19 AT20 AU13 AU14 AU15 AU16 AU17 AU18 AU19 AU20} [expr $i - 96]] [get_ports result_out[$i]]
    set_property IOSTANDARD LVCMOS33 [get_ports result_out[$i]]
}
