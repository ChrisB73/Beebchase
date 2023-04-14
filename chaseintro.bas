      REM Beeb Chase
      REM By Chris Bradburne
      REM Version 1.0 (07/04/2023)
      *EXEC
      *FX 15
      *FX 200,1
      HIMEM=&2600

      PROCm(2)

      *RUN Title

      FOR X%=&2F00 TO &2FF8 STEP 4
        !X%=-1
      NEXT
      *LOAD Story 2C00

      DIM k%(7)
      k%(0)=97
      k%(1)=66
      k%(2)=72
      k%(3)=104
      k%(4)=73

      DIM k$(7)
      k$(0)="Left"
      k$(1)="Right"
      k$(2)="Accelerate"
      k$(3)="Decelerate"
      k$(4)="Fire"

      A%=&AC:X%=0:Y%=255
      T%=((USR(&FFF4)DIV256)AND&FFFF)-1
      *FX 4,2

      X%=INKEY(1500)

      PROCm(7)

      A%=0
      REPEAT
        PROCtitle

        PRINT'TAB(10)"Keys:"
        FOR X%=0 TO 4
          PRINTCHR$(129)TAB(10)k$(X%);SPC(11-LEN(k$(X%)));"- ";FNkey(k%(X%))
        NEXT
        PRINT'TAB(9)CHR$(134)"f0 - Sound On/Off"

        PRINT''CHR$(130)TAB(5)"Redefine (K)eys, read (S)tory"
        PRINTCHR$(130)TAB(8)"or another key to start."

        A%=GET OR 32

        IF A%=115 PROCstory
        IF A%=107 PROCredefine

      UNTIL A%>0

      A%=RND(-TIME)
      !&8C=RND

      ?&88=k%(4)+128
      ?&89=k%(0)+128
      ?&8A=k%(1)+128
      ?&8B=k%(2)+128
      ?&8C=k%(3)+128

      *RUN Chase

      END

      DEFPROCm(M%)
      VDU 22,M%,23,1,0,0;0;0;0;
      ENDPROC

      DEFPROCstory
      P%=&2C00
      w$=""
      C%=0
      PROCnewscreen
      REPEAT
        c$=CHR$(?P%)
        w$=w$+c$
        C%=C%+1
        IF C%>39 PRINT';:C%=LEN(w$):L%=L%+1
        IF ?P%=13 PRINTw$'';:L%=L%+1:C%=0:w$=""
        IF L%>13 PROCc:PROCnewscreen
        IF c$=" " PRINTw$;:w$=""
        P%=P%+1
      UNTIL ?P%=255
      PROCc
      A%=0
      ENDPROC

      DEFPROCc
      PRINTTAB(5,23)CHR$(130);"Press any key to continue.";
      N%=GET
      ENDPROC

      DEFPROCnewscreen
      L%=0
      PROCtitle
      ENDPROC

      DEFFNgetkey
      REPEAT
        G%=TRUE
        K%=-1
        IF INKEY(-1) THEN K%=0
        IF INKEY(-2) THEN K%=1
        A%=121:X%=0:Y%=0
        IF K%=-1 THEN K%=(USR(&FFF4)DIV256)AND255
        IF K%=32 OR K%=113 OR K%=114 OR K%=115 THEN G%=FALSE:VDU 7
        FOR B%=0 TO 3
          IF k%(B%)=K% THEN G%=FALSE
        NEXT
      UNTIL K%<>255 AND K%<>112 AND G%=TRUE
      =K%

      DEFPROCredefine
      R%=FALSE
      REPEAT
        PROCtitle
        PRINT
        W%=TIME+50:REPEAT UNTIL TIME>W%
        FOR Z%=0 TO 3
          k%(Z%)=-1
        NEXT

        FOR Z%=0 TO 4
          PRINTTAB(5);CHR$(134);k$(Z%);SPC(12-LEN(k$(Z%)));"- ";
          k%(Z%)=FNgetkey
          PRINT FNkey(k%(Z%))
        NEXT
        PRINT''TAB(4);CHR$(129);CHR$(136);"Keys OK? (Y/N)"
        W%=TIME+50:REPEAT UNTIL TIME>W%
        *FX 21,0
        N$=GET$
        IF N$="Y" OR N$="y" THEN R%=TRUE
      UNTIL R%=TRUE
      A%=0
      ENDPROC

      DEFPROCtitle
      CLS
      PRINT
      FORD%=0TO1
        PRINTTAB(11)CHR$(141)+CHR$(132)+CHR$(157)+CHR$(134)+"Beeb Chase  "+CHR$(156)
      NEXT
      PRINTTAB(10)CHR$(131)"By Chris Bradburne"
      PRINTCHR$(133)"Based on Deathchase by Mervyn Estcourt"
      PRINT
      ENDPROC

      DEFFNkey(K%)
      LOCAL k$
      IF K%=0 THEN k$="Shift"
      IF K%=1 THEN k$="Ctrl"
      I%=-1
      S%=T%?K%
      RESTORE
      IF k$="" THEN REPEAT:READ I%,k$:UNTIL S%=I% OR I%=256
      IF I%=256 THEN k$=FNucase(S%)
      =k$

      DEFFNucase(C%)
      LOCAL c$
      c$=CHR$(S%)
      IF C%>96 AND C%<123 THEN c$=CHR$(S%-32)
      =c$

      DATA 0,"Tab",1,"Caps Lock",2,"Shift Lock",13,"Return",32,"Space",127,"Delete"
      DATA 129,"f1",130,"f2",131,"f3",132,"f4",132,"f5",133,"f6",134,"f7",135,"f8",136,"f9"
      DATA 139,"Copy",140,"Left",141,"Right",142,"Down",143,"Up",256,""
