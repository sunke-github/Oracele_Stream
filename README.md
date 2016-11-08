# Oracele_Stream
Solve stream apply error(ORA-00001,ORA-26787,ORA-26786). 
Uesage:
1, Create those procedure in oracle target. 
2, Got applyname and transactionId
3, execute procedure eg applyname is 'AP_O', and tractionId is '1234567'
   Begin
    EXECUTE_TRANSACTION_1('AP_0','1234567');
   END;
4, Good Luck.
    
