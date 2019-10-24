if(test-path -path ".\\work"){
    Remove-Item -Path ".\\work" -Recurse -Force
    Remove-Item -Path ".\\transcript" -Force
    Remove-Item -Path ".\\modelsim.ini" -Force
}

vlib work
vmap work work
vlog -f filelist.f +acc=mnprt 
vsim sbox_tb -gui -novopt