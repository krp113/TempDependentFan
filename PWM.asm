#include p18f87k22.inc

    global  PWM_Setup, PWM_SetWidth
    
ADC    code
    
PWM_Setup		    ;Set up/configuration of PWM
    
    movlw   0xff
    movwf   PR2		    ;setting the value to maximum value the timer can hold
    movlw   b'00000001'
    movwf   T2CON	    ;writing to the T2CON register
    bsf	    T2CON, TMR2ON
    movlw   b'00001100'	    ;bit 4:5 represent the LSbs of the Duty Cycle
    movwf   CCP4CON	    ; writing to CCP4CON register (11xx) where x=0 in this case
    clrf    CCPR4L	    ; clearing the 8-bit register in case previous values stored within
    bcf	    TRISG, CCP4	    ; clearing the RG3 pin to make it output
    return

PWM_SetWidth		    ; sets pulse width  to value stored in W. This value can have a 10-bit resolution hence corresponding to 
			    ; 1024 diffrent pulse widths therefore discrete but precise value of the fan motor speed can be achieved. 
    movwf CCPR4L	    ; CCPR4L contains the 8 MSbs of the Duty Cycle
    return

    end