# Oracele_Stream
Solve stream apply error(ORA-00001,ORA-26787,ORA-26786). <br>
Uesage:<br>
1, Create those procedures in oracle target. <br>
2, Got applyname and transactionId<br>
3, execute procedure eg applyname is 'AP_0', and tractionId is '1234567'<br>
   Begin<br>
    EXECUTE_TRANSACTION_1('AP_0','1234567');<br>
   END;<br>
4, Good Luck.<br>
    
