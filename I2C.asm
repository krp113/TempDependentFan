#include p18f87k22.inc

    global  I2C_Setup
    
ADC    code		    ;why is ADC code required?

CPL equ 0    
CPH equ 1
 
I2C_Setup
     
    movlw   CPL
    movwf   TRISD, RC3
    movwf   TRISD, RC4  
    
    
    return
                            

    end