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

## ===============================
## VGA RED [3:0]
## Basys3: R0=G19, R1=H19, R2=J19, R3=N19
## ===============================
set_property PACKAGE_PIN G19 [get_ports {VGA_R[0]}]
set_property PACKAGE_PIN H19 [get_ports {VGA_R[1]}]
set_property PACKAGE_PIN J19 [get_ports {VGA_R[2]}]
set_property PACKAGE_PIN N19 [get_ports {VGA_R[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R[*]}]

## ===============================
## VGA GREEN [3:0]
## Basys3: G0=J17, G1=H17, G2=G17, G3=D17
## ===============================
set_property PACKAGE_PIN J17 [get_ports {VGA_G[0]}]
set_property PACKAGE_PIN H17 [get_ports {VGA_G[1]}]
set_property PACKAGE_PIN G17 [get_ports {VGA_G[2]}]
set_property PACKAGE_PIN D17 [get_ports {VGA_G[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G[*]}]

## ===============================
## VGA BLUE [3:0]
## Basys3: B0=N18, B1=L18, B2=K18, B3=J18
## ===============================
set_property PACKAGE_PIN N18 [get_ports {VGA_B[0]}]
set_property PACKAGE_PIN L18 [get_ports {VGA_B[1]}]
set_property PACKAGE_PIN K18 [get_ports {VGA_B[2]}]
set_property PACKAGE_PIN J18 [get_ports {VGA_B[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B[*]}]

## ===============================
## VGA SYNC
## Basys3: HS=P19, VS=R19
## ===============================
set_property PACKAGE_PIN P19 [get_ports {VGA_HS}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_HS}]

set_property PACKAGE_PIN R19 [get_ports {VGA_VS}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_VS}]
