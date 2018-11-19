#include p18f87k22.inc

    global  I2C_Setup
    
ADC    code		    ;why is ADC code required?

CPL equ 0    
CPH equ 1
 
I2C_Setup
     
    bsf	    TRISC, RC3	; RC3 and RC4 pins are involved with I2C communication. However the RC3/4 pins need to write to slave too. Therefore 
    bsf	    TRISC, RC4	; both pins receive input from the thermometer hence set to input pins
    movlw   b'00101000'	; there may be a problem with the MSb here, 5th bit enables the MSSP
    movwf   SSP1CON1	; control register 1 for MSSP 1
    movlw   b'00000000'	; set up bit for SSP1CON2
    movwf   SSP1CON2	; Control register 2 for MSSP 1
    
    return

; What are the fuctions I need?
 
;The set up function
;fuction to transfer serial data to MP
;function to input the serial data as the PWM control bit --> this what will ultimately control the motor speed. 
		     
I2C_Transmit
 return
                            

    end