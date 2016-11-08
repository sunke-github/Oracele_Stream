CREATE OR REPLACE PROCEDURE EXECUTE_TRANSACTION_1(applyname IN VARCHAR2,ltxnid IN VARCHAR2) IS 
-- create or replace type myvarray_list as varray(10) of varchar2(50);
--grant select on dba_constraints to DWESBSTREAMUSER;
--granT select on DBA_cons_columns to DWESBSTREAMUSER;
	i      NUMBER;                                                                                 
	x	   NUMBER;
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
	object_owner     VARCHAR2(30);
  	object_name      VARCHAR2(40);
  	key_column       myvarray_list;
  	remove_column   myvarray_list;
  	remove_flag     NUMBER;
  	remove_count    NUMBER;
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
    DBMS_OUTPUT.PUT_LINE(' --- Local Transaction ID: ' || txnid);                                 
  	DBMS_OUTPUT.PUT_LINE(' --- Source Database: ' || source);                                     
  	DBMS_OUTPUT.PUT_LINE(' ---Error in Message: '|| msgno);                                        
  	DBMS_OUTPUT.PUT_LINE(' ---Error Number: '||errno);                                             
  	DBMS_OUTPUT.PUT_LINE(' ---Message Text: '||errmsg);
	i := msgno;
	loopdog :=0;
  	WHILE i <= msgcnt LOOP 
  		IF loopdog > msgcnt then
  			RAISE_APPLICATION_ERROR(-20002,'Insert or Delete error. please check your procedure.');
	    END IF;
  		loopdog :=loopdog+1;
  		DBMS_OUTPUT.PUT_LINE('---message: ' || i);                                                      
    	lcr := DBMS_APPLY_ADM.GET_ERROR_MESSAGE(i, txnid); -- gets the LCR                                                                                                        
		typenm := lcr.GETTYPENAME();                                                                 
    	DBMS_OUTPUT.PUT_LINE('type name: ' || typenm);                                               
		IF (typenm = 'SYS.LCR$_ROW_RECORD') THEN
			res := lcr.GETOBJECT(rowlcr);                                                            
			command := rowlcr.GET_COMMAND_TYPE();                                                  
			DBMS_OUTPUT.PUT_LINE('command type name: ' || command);                                
			IF command = 'INSERT' THEN
				rowlcr.SET_COMMAND_TYPE('DELETE');                                                                                             
				new_values := rowlcr.GET_VALUES('new');                                              
				-- Set the old values in the row LCR to the new values in the row LCR                
				rowlcr.SET_VALUES('old', new_values);                                                
				-- Set the old values in the row LCR to NULL                                         
				rowlcr.SET_VALUES('new', NULL);                                                             
				old_values := rowlcr.GET_VALUES('old');			
				-- Apply the row LCR as an DELETE FROM  the  table                                      
				object_name :=rowlcr.GET_OBJECT_NAME();
				object_owner :=rowlcr.GET_OBJECT_OWNER();
				key_column := myvarray_list();   --init array.	
				i :=1;
				FOR emm IN (select DISTINCT CO.COLUMN_NAME from 
							DBA_cons_columns CO, dba_constraints PK 
								where CO.constraint_name = PK.constraint_name  
								AND CO.OWNER = PK.OWNER 
								AND PK.constraint_type IN ('P','C','U') 
								and PK.table_name = object_name 
								AND PK.OWNER=object_owner) LOOP	  							  		
					DBMS_OUTPUT.PUT_LINE('key column ' || emm.COLUMN_NAME);	
					key_column.extend; 
					key_column(i) := emm.COLUMN_NAME; 
					i :=i+1;
				END LOOP;					
				remove_column := myvarray_list();   --init array.
  				remove_count := 1;	
				FOR i in 1..old_values.count LOOP
  					IF old_values(i) IS NOT NULL THEN
    					--DBMS_OUTPUT.PUT_LINE('old('||i||'):'||old_values(i).column_name);
    					x :=1;
    					remove_flag :=1;
  						WHILE x <= key_column.count AND remove_flag=1 loop
         					--dbms_output.put_line('key_column('||x||')='||key_column(x));
         					IF old_values(i).column_name = key_column(x) THEN
         						remove_flag :=0;
         					END IF;
         					x :=x +1;
     					END loop;
     					IF remove_flag = 1 then 
     						remove_column.extend; 
							remove_column(remove_count) := old_values(i).column_name;
							remove_count :=remove_count+1;
     					END IF;
  					END IF;
    			END LOOP;	
    			
    			--------------------------------------------------------------------------
    			--remove_column :=STRSPLIT(errmsg);
    			---------------------------------------------------------------------------
    			
    			FOR x in 1..remove_column.count loop
         			dbms_output.put_line('remove_column('||x||')='||remove_column(x));
         			rowlcr.DELETE_COLUMN(remove_column(x),'old');
     			END loop;
    			rowlcr.EXECUTE(true);                                                                
			END IF;
			BEGIN                                                                                  
			dbms_apply_adm.execute_all_errors(applyname); 
			--dbms_apply_adm.EXECUTE_ERROR(ltxnid);                                      
			return;                                                                            
			EXCEPTION when OTHERS then                                                         
				SELECT MESSAGE_NUMBER  INTO  i FROM DBA_APPLY_ERROR  WHERE LOCAL_TRANSACTION_ID =  ltxnid;
				v_code := SQLCODE;
	            v_errm := SUBSTR(SQLERRM, 1, 1024);
	            DBMS_OUTPUT.PUT_LINE('Error message: ' || v_errm);
	            IF v_code = -1 then 
	            	DBMS_OUTPUT.PUT_LINE('Error code(-1): ' || v_code);
	            	--null;
	            ELSIF v_code = -26786 then
	            	DBMS_OUTPUT.PUT_LINE('Error code(-26786): ' || v_code);
	            	RAISE_APPLICATION_ERROR(-20786,v_errm);
	            ELSIF v_code = -26787 then
	            	DBMS_OUTPUT.PUT_LINE('Error code(-26787): ' || v_code);
	            	RAISE_APPLICATION_ERROR(-20787,v_errm); 
	            ELSE 
	            	RAISE_APPLICATION_ERROR(-20000,v_errm);
	            END IF;	                                                                          
			END;	
		END IF;
	END LOOP;      --loop
END EXECUTE_TRANSACTION_1; 