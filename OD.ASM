PUBLIC          OUTPUTDECIMAL

OUTD_DATA       SEGMENT
    PRECISION   EQU     6   ;һ��Ҫ��ż��MUST BE EVEN
    BIGDECM     DQ      1000000.0
    BCDSPC      DT      ?
    MOSTSIG     DB      ?
    LESTSIG     DB      ?
OUTD_DATA       ENDS

OUTD_CODE       SEGMENT
                ASSUME CS:OUTD_CODE, DS:OUTD_DATA
                
                
    OUTPUTDECIMAL       PROC    FAR
            ;���һ��С����
            ;���룺SI��64bitС����ƫ�Ƶ�ַ��
            ;���������Χ��-100000~-0.00000001, 0.00000001~100000
            ;�����ʽ�����8λС������25.00152225, 33.441��
            PUSH        AX
            PUSH        BX
            PUSH        CX
            PUSH        DX
            PUSHF
            
            PUSH        DS
            
            FLD         QWord Ptr [SI]
            MOV         AX, OUTD_DATA
            MOV         DS, AX
            
            FMUL        QWord Ptr BIGDECM       ;��һ���򣬾Ϳ����Ȼ�������
            
            FBSTP       BCDSPC      ;����õ�BCD
            
            ;��ʼ��BCD�����λ�����λ��Ч����
            MOV         BX, Offset BCDSPC
            MOV         CX, 0H
            
            MOV         MOSTSIG, 0D
            MOV         LESTSIG, 17D
            
    EVENBIT:
            SHR         CX, 1H
            MOV         DI, CX
            AND         DI, 0FH
            MOV         DL, [BX][DI]
            SHL         CX, 1H
            TEST        DL, 0FH
            JNZ         CHKUPDATESIG
    CHKEND_EVEN: 
            INC         CX
            
    ODDBIT:
            TEST        DL, 0F0H
            JNZ         CHKUPDATESIG
    CHKEND_ODD: 
            INC         CX
            CMP         CX, 17D
            JBE         EVENBIT
            JMP         AFTERSETSIG
            
    CHKUPDATESIG:
            CMP         MOSTSIG, CL
            JNB         CHKUPDATELESTSIG
            MOV         MOSTSIG, CL
    CHKUPDATELESTSIG:
            CMP         LESTSIG, CL
            JNA         CHKUPDATELESTSIG_END
            MOV         LESTSIG, CL
    CHKUPDATELESTSIG_END:
            TEST        CL, 1H
            JZ          CHKEND_EVEN
            JMP         CHKEND_ODD
            
    ;��ʱMOSTSIG��LESTSIG�ֱ𴢴�С�������λ�����λ
    AFTERSETSIG:
            CMP         MOSTSIG, 6D
            JAE         AFTER_CORRECT_MOSTSIG
            MOV         MOSTSIG, 6D
    AFTER_CORRECT_MOSTSIG:
            CMP         LESTSIG, 6D
            JBE         AFTER_CORRECT_LESTSIG
            MOV         LESTSIG, 6D
    AFTER_CORRECT_LESTSIG:
            
    ;��ʼ��ӡ
    PRINTDIGIT          MACRO   digit
            PUSH        DX
            MOV         DL, digit
            AND         DL, 0FH
            OR          DL, 30H
            MOV         AH, 02H
            INT         21H
            POP         DX
    ENDM
    ;�ȴ�ӡ����
            MOV         DL, 9[BX]
            TEST        DL, 80H
            JZ          PRINTDIGITS
            PUSH        DX
            MOV         DL, '-'
            MOV         AH, 02H
            INT         21H
            POP         DX
            
    PRINTDIGITS:
            XOR         CX, CX
            MOV         CL, MOSTSIG
            TEST        CL, 1H
            JNZ         PRINTDIGIT_ODD
            ROR         CX, 1H
            MOV         DI, CX
            ROL         CX, 1H
            AND         DI, 0FH
            MOV         DL, [BX][DI]
            JMP         PRINTDIGIT_EVEN
            
    PRINTDIGIT_ODD:
            PUSH        CX
            SHR         CX, 1H
            MOV         DI, CX
            AND         DI, 0FH
            MOV         DL, [BX][DI]
            MOV         CL, 4H
            ROR         DL, CL
            POP         CX
            
            CMP         CL, PRECISION - 1D
            JNZ         DIRECT_PRINTDIGIT
            
            PUSH        DX
            MOV         DL, '.'
            MOV         AH, 02H
            INT         21H
            POP         DX
            
    DIRECT_PRINTDIGIT:
            PRINTDIGIT  DL
            
            PUSH        CX
            MOV         CL, 4H
            ROR         DL, CL
            POP         CX
            
            DEC         CL
            CMP         CL, LESTSIG
            JL          PRINTDIGIT_END
    PRINTDIGIT_EVEN:
            PRINTDIGIT  DL
            DEC         CL
            CMP         CL, LESTSIG
            JNL         PRINTDIGIT_ODD
            
    PRINTDIGIT_END:
    
            POP         DS
            POPF
            POP         DX
            POP         CX
            POP         BX
            POP         AX
            RET
            
    OUTPUTDECIMAL       ENDP
    
OUTD_CODE               ENDS
END