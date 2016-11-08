# Oracele_Stream
Solve stream apply error(ORA-00001,ORA-26787,ORA-26786). <br>
Uesage:<br>
1,
create or replace type myvarray_list as varray(10) of varchar2(50);<br>
grant select on dba_constraints to DWESBSTREAMUSER;<br>
granT select on DBA_cons_columns to DWESBSTREAMUSER;<br>
2, Create those procedures in oracle target. <br>
3, Got applyname and transactionId<br>
4, execute procedure eg applyname is 'AP_0', and tractionId is '1234567'<br>
   Begin<br>
    EXECUTE_TRANSACTION_1('AP_0','1234567');<br>
   END;<br>
5, Good Luck.<br>
    
