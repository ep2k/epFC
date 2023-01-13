# Clock
create_clock -name clock_in_50mhz -period 20.000 [get_ports {pin_clk}]
derive_pll_clocks
derive_clock_uncertainty
create_generated_clock -name clk -source [get_nets {clock_generator|base_clk}] -divide_by 4 [get_nets {clock_generator|counter[1]}]
create_generated_clock -name pad_clk -source [get_ports {pin_clk}] -divide_by 100 [get_nets {clock_generator|pad_clk}]

# False path
set_clock_groups -asynchronous -group [get_clocks {clk}] -group [get_clocks {pad_clk}]
set_clock_groups -asynchronous -group [get_clocks {clk}] -group [get_clocks {clock_in_50mhz}]
