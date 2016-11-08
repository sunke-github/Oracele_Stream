CREATE OR REPLACE PROCEDURE EXECUTE_TRANSACTION_26787(applyname IN VARCHAR2,ltxnid IN VARCHAR2) IS                      
  i      NUMBER;   
  loopdog NUMBER;
  txnid  VARCHAR2(30);                                                                          
  source VARCHAR2(128);                                                                         
  msgno  NUMBER;                                                                                
  msgcnt NUMBER;                                                                                
  errno  NUMBER;                                                                                
  errmsg VARCHAR2(2000);                                                                        
  lcr    ANYDATA;                                                                               
  rowlcr    SYS.LCR$_ROW_RECORD;                                                                
  typenm    VARCHAR2(61);                                                                       
  res       NUMBER;                                                                             
  command      VARCHAR2(10);                                                                    
  old_values   SYS.LCR$_ROW_LIST;                                                             
  new_values   SYS.LCR$_ROW_LIST;                                                                                                                           
  v_code  NUMBER;
  v_errm  VARCHAR2(1024); 
BEGIN                                                                                           
  SELECT LOCAL_TRANSACTION_ID,                                                                  
         SOURCE_DATABASE,                                                                       
         MESSAGE_NUMBER,                                                                        
         MESSAGE_COUNT,                                                                         
         ERROR_NUMBER,                                                                          
         ERROR_MESSAGE                                                                          
      INTO txnid, source, msgno, msgcnt, errno, errmsg                                          
      FROM DBA_APPLY_ERROR                                                                      
      WHERE LOCAL_TRANSACTION_ID =  ltxnid;                                                     
  DBMS_OUTPUT.PUT_LINE('--- Local Transaction ID: ' || txnid);                                
  DBMS_OUTPUT.PUT_LINE('--- Source Database: ' || source);                                    
  DBMS_OUTPUT.PUT_LINE('---Error in Message: '|| msgno);                                       
  DBMS_OUTPUT.PUT_LINE('---Error Number: '||errno);                                            
  DBMS_OUTPUT.PUT_LINE('---Message Text: '||errmsg);                                           
  i := msgno;
  loopdog :=0;  
  WHILE i <= msgcnt  LOOP   
  	IF loopdog > msgcnt then
	   RAISE_APPLICATION_ERROR(-20002,'Insert or Delete error. please check your procedure.');
  	END IF;
  	
  	loopdog :=loopdog+1;
  	DBMS_OUTPUT.PUT_LINE('--message: ' || i);                                                     
    lcr := DBMS_APPLY_ADM.GET_ERROR_MESSAGE(i, txnid); -- gets the LCR                          
    --print_lcr(lcr);                                                                             
	typenm := lcr.GETTYPENAME();                                                                
    DBMS_OUTPUT.PUT_LINE('type name: ' || typenm);                                              
	IF (typenm = 'SYS.LCR$_ROW_RECORD') THEN                                                    
		res := lcr.GETOBJECT(rowlcr);                                                           
		command := rowlcr.GET_COMMAND_TYPE();                                                 
		DBMS_OUTPUT.PUT_LINE('command type name: ' || command);                               
		IF command = 'DELETE' THEN                                                              
			-- Set the command_type in the row LCR to INSERT                                    
			rowlcr.SET_COMMAND_TYPE('INSERT');                                                                                            
			old_values := rowlcr.GET_VALUES('old');                                             
			-- Set the old values in the row LCR to the new values in the row LCR               
			rowlcr.SET_VALUES('new', old_values);                                               
			-- Set the old values in the row LCR to NULL                                        
			rowlcr.SET_VALUES('old', NULL);                                                            
			-- Apply the row LCR as an INSERT into the hr.emp_del table                                                                                                    
			rowlcr.EXECUTE(true);                                                                                                                                           
		ELSIF command = 'UPDATE' THEN                                                         
			BEGIN                                                                             
				old_values := rowlcr.GET_VALUES('old');                                       
				new_values := rowlcr.GET_VALUES('new');                                       
				rowlcr.EXECUTE(true);                                                         
				rowlcr.SET_VALUES('new', old_values);                                         
				rowlcr.SET_VALUES('old', new_values);                                         
				rowlcr.EXECUTE(true);                                                         
				EXCEPTION when OTHERS then                                                    
					rowlcr.SET_COMMAND_TYPE('INSERT');                                        
					rowlcr.SET_VALUES('new', old_values);                                                
					-- Set the old values in the row LCR to NULL                                         
					rowlcr.SET_VALUES('old', NULL);                                           
					rowlcr.EXECUTE(true);                                                     
			END;                                                                              
		END IF;                                                                               
		BEGIN                                                                                 
			dbms_apply_adm.execute_all_errors(applyname);  
			--dbms_apply_adm.execute_error(ltxnid);                                   
			return;                                                                           
			EXCEPTION when OTHERS then                                                        
				SELECT MESSAGE_NUMBER  INTO  i FROM DBA_APPLY_ERROR  WHERE LOCAL_TRANSACTION_ID =  ltxnid;
				v_code := SQLCODE;
	            v_errm := SUBSTR(SQLERRM, 1, 1024);
	            DBMS_OUTPUT.PUT_LINE('Error message: ' || v_errm);
	            IF v_code = -26787 then 
	            	DBMS_OUTPUT.PUT_LINE('Error code(-26787): ' || v_code);
	            	--null;
	            ELSIF v_code = -26786 then
	            	DBMS_OUTPUT.PUT_LINE('Error code(-26786): ' || v_code);
	            	RAISE_APPLICATION_ERROR(-20786,v_errm);
	            ELSIF v_code = -1 then
	            	DBMS_OUTPUT.PUT_LINE('Error code(-1): ' || v_code);
	            	RAISE_APPLICATION_ERROR(-20001,v_errm);   
	            ELSE 
	            	RAISE_APPLICATION_ERROR(-20000,v_errm);
	            END IF;	                                                                         
		END;                                                                                  
	END IF;                                                                                   
  END LOOP;                                                                                   
END EXECUTE_TRANSACTION_26787;