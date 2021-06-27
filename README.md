# verilog_APB_SPI_interface
SPI interface connect to APB BUS with Verilog HDL

This project implement an SPI module with an APB Bus interface. 
The project contains 4 modules: APB_interface, SPI_master, 4 SPI_slave, and the testbench.
Another module is the SPI_testmodul_2. In this part i connect the master and 4 spi slaves to each other.
The test application send 01010101 to the APB interface, the interface give it to the master. 
The master write and read the data from the SPI_slaves at same time. 
During the test all 4 spi tansmission mode was performed, and each slave send's back their transmisson mode 111100xx, xx: 00 | 01 | 11 | 10
