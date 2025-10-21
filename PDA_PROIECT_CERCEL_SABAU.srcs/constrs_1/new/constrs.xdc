## ====================================================================
## Clock (100 MHz onboard oscillator)
## ====================================================================
set_property PACKAGE_PIN W5 [get_ports clk100]
set_property IOSTANDARD LVCMOS33 [get_ports clk100]

## ====================================================================
## Push Button (Center)
## ====================================================================
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## ====================================================================
## Reset Input (map to SW0)
## ====================================================================
set_property PACKAGE_PIN V17 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

## ====================================================================
## VGA Red[3:0]
## ====================================================================
set_property PACKAGE_PIN A3 [get_ports {red[0]}]
set_property PACKAGE_PIN B4 [get_ports {red[1]}]
set_property PACKAGE_PIN C5 [get_ports {red[2]}]
set_property PACKAGE_PIN A4 [get_ports {red[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {red[*]}]

## ====================================================================
## VGA Green[3:0]
## ====================================================================
set_property PACKAGE_PIN C6 [get_ports green[0]]
set_property PACKAGE_PIN A5 [get_ports green[1]]
set_property PACKAGE_PIN B6 [get_ports green[2]]
set_property PACKAGE_PIN A6 [get_ports green[3]]
set_property IOSTANDARD LVCMOS33 [get_ports green[*]]

## ====================================================================
## VGA Blue[3:0]
## ====================================================================
set_property PACKAGE_PIN B7 [get_ports {blue[0]}]
set_property PACKAGE_PIN C7 [get_ports {blue[1]}]
set_property PACKAGE_PIN D7 [get_ports {blue[2]}]
set_property PACKAGE_PIN D8 [get_ports {blue[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {blue[*]}]

## ====================================================================
## VGA Sync Signals
## ====================================================================
set_property PACKAGE_PIN B11 [get_ports hsync]
set_property PACKAGE_PIN B12 [get_ports vsync]
set_property IOSTANDARD LVCMOS33 [get_ports {hsync vsync}]
