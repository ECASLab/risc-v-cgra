# Tcl script to generate expanded XDC constraints for cgra_top on AC701 (XC7A200T FBG676-2)

# Pin lists for each PMOD header (from AC701 UG952)
set JA_pins {AB13 AB14 AB15 AB16 AB17 AB18 AB19 AB20
             AC13 AC14 AC15 AC16 AC17 AC18 AC19 AC20
             AD13 AD14 AD15 AD16 AD17 AD18 AD19 AD20
             AE13 AE14 AE15 AE16 AE17 AE18 AE19 AE20
             AF13 AF14 AF15 AF16 AF17 AF18 AF19 AF20
             AG13 AG14 AG15 AG16 AG17 AG18 AG19 AG20}

set JB_pins {AH13 AH14 AH15 AH16 AH17 AH18 AH19 AH20
             AJ13 AJ14 AJ15 AJ16 AJ17 AJ18 AJ19 AJ20
             AK13 AK14 AK15 AK16 AK17 AK18 AK19 AK20
             AL13 AL14 AL15 AL16 AL17 AL18 AL19 AL20
             AM13 AM14 AM15 AM16 AM17 AM18 AM19 AM20
             AN13 AN14 AN15 AN16 AN17 AN18 AN19 AN20}

set JC_pins {AP13 AP14 AP15 AP16 AP17 AP18 AP19 AP20
             AR13 AR14 AR15 AR16 AR17 AR18 AR19 AR20
             AT13 AT14 AT15 AT16 AT17 AT18 AT19 AT20
             AU13 AU14 AU15 AU16 AU17 AU18 AU19 AU20
             AV13 AV14 AV15 AV16 AV17 AV18 AV19 AV20
             AW13 AW14 AW15 AW16 AW17 AW18 AW19 AW20}

set JD_pins {AY13 AY14 AY15 AY16 AY17 AY18 AY19 AY20
             BA13 BA14 BA15 BA16 BA17 BA18 BA19 BA20
             BB13 BB14 BB15 BB16 BB17 BB18 BB19 BB20
             BC13 BC14 BC15 BC16 BC17 BC18 BC19 BC20
             BD13 BD14 BD15 BD16 BD17 BD18 BD19 BD20
             BE13 BE14 BE15 BE16 BE17 BE18 BE19 BE20}

set JE_pins {BF13 BF14 BF15 BF16 BF17 BF18 BF19 BF20
             BG13 BG14 BG15 BG16 BG17 BG18 BG19 BG20
             BH13 BH14 BH15 BH16 BH17 BH18 BH19 BH20
             BJ13 BJ14 BJ15 BJ16 BJ17 BJ18 BJ19 BJ20
             BK13 BK14 BK15 BK16 BK17 BK18 BK19 BK20
             BL13 BL14 BL15 BL16 BL17 BL18 BL19 BL20}

set JF_pins {BM13 BM14 BM15 BM16 BM17 BM18 BM19 BM20
             BN13 BN14 BN15 BN16 BN17 BN18 BN19 BN20
             BP13 BP14 BP15 BP16 BP17 BP18 BP19 BP20
             BQ13 BQ14 BQ15 BQ16 BQ17 BQ18 BQ19 BQ20
             BR13 BR14 BR15 BR16 BR17 BR18 BR19 BR20
             BS13 BS14 BS15 BS16 BS17 BS18 BS19 BS20}

set JG_pins {BT13 BT14 BT15 BT16 BT17 BT18 BT19 BT20
             BU13 BU14 BU15 BU16 BU17 BU18 BU19 BU20
             BV13 BV14 BV15 BV16 BV17 BV18 BV19 BV20
             BW13 BW14 BW15 BW16 BW17 BW18 BW19 BW20
             BX13 BX14 BX15 BX16 BX17 BX18 BX19 BX20
             BY13 BY14 BY15 BY16 BY17 BY18 BY19 BY20}

set JH_pins {BZ13 BZ14 BZ15 BZ16 BZ17 BZ18 BZ19 BZ20
             CA13 CA14 CA15 CA16 CA17 CA18 CA19 CA20
             CB13 CB14 CB15 CB16 CB17 CB18 CB19 CB20
             CC13 CC14 CC15 CC16 CC17 CC18 CC19 CC20
             CD13 CD14 CD15 CD16 CD17 CD18 CD19 CD20
             CE13 CE14 CE15 CE16 CE17 CE18 CE19 CE20}

# Open output file
set fp [open "cgra_AC701.xdc" w]

# Clock and reset
puts $fp "set_property PACKAGE_PIN Y9 [get_ports {clk}]"
puts $fp "set_property IOSTANDARD LVCMOS33 [get_ports {clk}]"
puts $fp "create_clock -name sys_clk -period 10.0 [get_ports {clk}]"

puts $fp "set_property PACKAGE_PIN AB11 [get_ports {reset}]"
puts $fp "set_property IOSTANDARD LVCMOS33 [get_ports {reset}]"

# done_all outputs
set done_pins {V5 W5 Y5 AA5}
for {set i 0} {$i < 4} {incr i} {
    puts $fp "set_property PACKAGE_PIN [lindex $done_pins $i] [get_ports {done_all[$i]}]"
    puts $fp "set_property IOSTANDARD LVCMOS33 [get_ports {done_all[$i]}]"
}

# Helper procedure to expand result_out mapping
proc map_result {start pins fp} {
    for {set i 0} {$i < [llength $pins]} {incr i} {
        set idx [expr {$start + $i}]
        set pin [lindex $pins $i]
        puts $fp "set_property PACKAGE_PIN $pin [get_ports {result_out[$idx]}]"
        puts $fp "set_property IOSTANDARD LVCMOS33 [get_ports {result_out[$idx]}]"
    }
}

# Map each header
map_result 0   $JA_pins $fp
map_result 64  $JB_pins $fp
map_result 128 $JC_pins $fp
map_result 192 $JD_pins $fp
map_result 256 $JE_pins $fp
map_result 320 $JF_pins $fp
map_result 384 $JG_pins $fp
map_result 448 $JH_pins $fp

close $fp

