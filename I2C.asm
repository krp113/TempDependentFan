#include p18f87k22.inc

    global I2C_Config, I2C_Temp_Conversion, I2C_Read_T_Data, I2C_StatReg_Display, I2C_Ack_Display
    
    ADC    code		    ;why is 'ADC code' required here?

L equ 0    
H equ 1

;Prior to starting temperature conversion, the configuration must be done
 
I2C_Config ; configuring the I2C slave by writing to the 'configuration register'
	
    bsf	    TRISC, RC3	; RC3 and RC4 pins are involved with I2C communication. However the RC3/4 pins need to write to slave too. Therefore 
    bsf	    TRISC, RC4	; only the data line is receiving input from the thermometer. 
			;So the data line is TRISC, RC3 = 1, and RC4 is output!!
			
    movlw   b'00111111'	; byte transferred into SSP1ADD to set the lowest possible clock frequency
			; clock = Fosc / (SSP1ADD + 1); taking Fosc to be 64Mhz
    movwf   SSP1ADD	; clock set to the min frequency of 125kHz
    
    movlw   b'00101000'	; there may be a problem with the MSb here, 5th bit enables the MSSP
    movwf   SSP1CON1	; control register 1 for MSSP 1
    
    movlw   b'00000001'	; Control byte for START condition
    movwf   SSP1CON2	; Control register 2 for MSSP 1
    
    movlw   b'10010000'	; Control byte to be sent to the slave, <1:3> bits is the slave address
    movwf   SSP1BUF	; <0> = 0 means I want to write to the slave
    
    ;Here The MSSP module generates an interrupt at the end of the ninth clock cycle 
    ;by setting the SSPxIF bit.
    
    movlw   0xAC	; access configuration command byte
    movwf   SSP1BUF	; reloading SSP1BUF with the command byte
    
    ; Here The MSSP module generates an interrupt at the end of the ninth clock cycle 
    ;by setting the SSPxIF bit.
    
    movlw   b'0000100'	; configuration byte, setting resolution to 10bytes = PWM duty cycle resolution
    movwf   SSP1BUF
    
    ;Here The MSSP module generates an interrupt at the end of the ninth clock cycle 
    ;by setting the SSPxIF bit.
    
    movlw   b'00000100'	; Control byte for STOP condition
    movwf   SSP1CON2
    ;Interrupt is generated once the STOP condition is complete
    return
    
I2C_Temp_Conversion
    
    movlw   b'00101000'	; 5th bit enables the MSSP
    movwf   SSP1CON1	; control register 1 for MSSP 1
    
    movlw   b'00000001'	; Control byte for START condition
    movwf   SSP1CON2	; Control register 2 for MSSP 1
    
    movlw   b'10010000'	; Control byte to be sent to the slave, <1:3> bits is the slave address
    movwf   SSP1BUF	; <0> = 0 means I want to WRITE to the slave
    
    ;Here The MSSP module generates an interrupt at the end of the ninth clock cycle 
    ;by setting the SSPxIF bit.
    
    movlw   0x51	; initiate temperature conversion
    movwf   SSP1BUF	; reloading SSP1BUF with the command byte
    
    ;Here The MSSP module generates an interrupt at the end of the ninth clock cycle 
    ;by setting the SSPxIF bit.
    
    movlw   b'00000100'	; Control byte for STOP condition
    movwf   SSP1CON2
    ;Interrupt is generated once the STOP condition is complete
    return
    
I2C_Read_T_Data
    
    movlw   b'00101000'	
    movwf   SSP1CON1	
    
    movlw   b'00000001'	; Control byte for START condition
    movwf   SSP1CON2	
    
    movlw   b'10010000'	; Control byte to be sent to the slave, <1:3> bits is the slave address
    movwf   SSP1BUF	; <0> = 0 means I want to WRITE to the slave first before I READ
    
    ;Here The MSSP module generates an interrupt at the end of the ninth clock cycle 
    ;by setting the SSPxIF bit.
    
    movlw   0xAA	; Read Temperature register command byte
    movwf   SSP1BUF	; reloading SSP1BUF with the command byte
    
    ;Here The MSSP module generates an interrupt at the end of the ninth clock cycle 
    ;by setting the SSPxIF bit. 
    ;NEED A REPEAT START HERE!!! NOT STOP THEN START AGAIN...MAY CAUSE ISSUES
    
    movlw   b'00000010' ;setting the RSEN bit to 1, which eventually causes a REPEAT START condition
    movwf   SSP1CON2   
    ;probably need a delay here to ensure RSEN takes effect
    movlw   b'10010001'	; Control byte to be sent to the slave, <1:3> bits is the slave address
    movwf   SSP1BUF	; <0> = 1 means NOW I want to READ from the slave 
			
			;here MASTER must respond to slave by sending an ACK for the first Temperature byte
			;then a NACK for the second Temperautre byte. T is recorded in 2 bytes, but with 10-bit resolution
        
    ;Here The MSSP module generates an interrupt at the end of the ninth clock cycle 
    ;by setting the SSPxIF bit.
    
    movlw   b'00000100'	; Control byte for STOP condition
    movwf   SSP1CON2
    ;Interrupt is generated once the STOP condition is complete

    return
    
    ;one major issue is that the Microprocessor receives the temperature data with the MSb transferred first. 
    ;therefore I require a function to reverse the data bits which can then be input into Duty cycle function
    
    ;TH and TL registers in the slave can be used to set up my condition for starting the fan. 
    ;THF -> 1 if T > TH, TLF -> 1 if T < TL. Therefore I will need to READ the THF and TLF bits to start the 
    ;fan once the TH bit is 1. The THF, TLF bits remain as 1 until they're reset by the user which is a problem too
    ;because the point of the fan is to be automated when the program is running. Want it to stop once the temperature falls
    ;below TH
I2C_StatReg_Display ;display on PORTD
    clrf    LATD
    movlw   0x00
    movwf   TRISD, ACCESS
    movff   SSP1STAT, PORTD
    return
    
I2C_Ack_Display	;display on PORTE
    clrf    LATE
    movlw   0x00
    movwf   TRISE, ACCESS
    movff   SSP1CON2, PORTE
end
    