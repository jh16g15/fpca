
puts "Adding 'write(address, value)' and 'read(address)' commands to Vivado"

proc reset {} {
    puts "Resetting hw_axi_1"
    reset_hw_axi [get_hw_axis hw_axi_1]
}

proc write {address value} {
    reset_hw_axi [get_hw_axis hw_axi_1]
    set address [string range $address 2 [expr {[string length $address]-1}]]
    #create_hw_axi_txn -quiet -force wr_tx [get_hw_axis hw_axi_1] -address $address -data $value -len 1 -type write
    create_hw_axi_txn -force wr_tx [get_hw_axis hw_axi_1] -address $address -data $value -len 1 -type write
    #run_hw_axi -quiet wr_tx
    run_hw_axi wr_tx
}

proc read {address} {
    reset_hw_axi [get_hw_axis hw_axi_1]
    set address [string range $address 2 [expr {[string length $address]-1}]]
    #create_hw_axi_txn -quiet -force rd_tx [get_hw_axis hw_axi_1] -address $address -len 1 -type read
    create_hw_axi_txn -force rd_tx [get_hw_axis hw_axi_1] -address $address -len 1 -type read
    # run_hw_axi -quiet rd_tx
    run_hw_axi rd_tx
    return 0x[get_property DATA [get_hw_axi_txn rd_tx]]
}