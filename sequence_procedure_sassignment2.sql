--------------------------------------------------------------------------------------------------
-- Sequences

CREATE SEQUENCE ECName_seq
  START WITH 100
  INCREMENT BY 1
  NOCACHE;
  
  
  CREATE SEQUENCE individual_seq
  START WITH 100
  INCREMENT BY 1
  NOCACHE;
  
  CREATE SEQUENCE individual_ECName_seq
  START WITH 100
  INCREMENT BY 1
  NOCACHE;
  
CREATE SEQUENCE address_seq
  START WITH 100
  INCREMENT BY 1
  NOCACHE;
  
  CREATE SEQUENCE tuner_address_seq
  START WITH 100
  INCREMENT BY 1
  NOCACHE;
  
  CREATE SEQUENCE tuner_seq
  START WITH 100
  INCREMENT BY 1
  NOCACHE;
  
  
  CREATE SEQUENCE parts_seq
  START WITH 100
  INCREMENT BY 1
  NOCACHE;
  
  CREATE SEQUENCE repair_parts_seq
  START WITH 100
  INCREMENT BY 1
  NOCACHE;
  
  CREATE SEQUENCE repair_seq
  START WITH 100
  INCREMENT BY 1
  NOCACHE;
  
  
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- repair_pkg package specification
CREATE or REPLACE PACKAGE repair_pkg AS
    
	-- Procedure to change parts
	PROCEDURE change_parts (
		p_idrepair IN repair_parts.repair_IdRepair%TYPE,
   		p_partsreplaced IN parts.partsreplaced%TYPE
	);

    -- Function to create a new repair record
    FUNCTION new_repair(
        p_repairdate IN repair.RepairDate%TYPE,
        p_issuedescription IN repair.IssueDescription%TYPE,
        p_isurgent IN repair.IsUrgent%TYPE,
		p_specialnotes IN repair.SpecialNotes%TYPE,
		p_partsreplaced IN parts.partsreplaced%TYPE
    ) RETURN INTEGER;

END repair_pkg;
	
CREATE OR REPLACE PACKAGE BODY repair_pkg AS

	PROCEDURE change_parts (
		p_idrepair IN repair_parts.repair_IdRepair%TYPE,
   		p_partsreplaced IN parts.partsreplaced%TYPE
	) IS
		v_parts_id parts.IdParts%TYPE;
        v_repair_parts_id repair_parts.IdRepairParts%TYPE;    
	BEGIN
        BEGIN
            -- Check if the parts already exists in the parts table
            SELECT IdParts INTO v_parts_id
            FROM parts
            WHERE PartsReplaced = p_partsreplaced;
        EXCEPTION
            -- If the parts doesn't exist, insert a new parts
            WHEN NO_DATA_FOUND THEN
            INSERT INTO parts (IdParts, PartsReplaced)
            VALUES (PARTS_SEQ.NEXTVAL, p_partsreplaced)
            RETURNING IdParts INTO v_parts_id;
        END;
		BEGIN
            -- Check if there's an existing parts for the repair in repair_parts table
            SELECT IdRepairParts INTO v_repair_parts_id
            FROM repair_parts
            WHERE Repair_IdRepair = p_idrepair
            AND enddate IS NULL;
			
			-- Parts exists for the repair, update the current entry
            IF v_repair_parts_id IS NOT NULL THEN
                UPDATE repair_parts
                SET enddate = SYSDATE
                WHERE IdRepairParts = v_repair_parts_id;
                
                -- Insert a new entry in the repair_parts table with sysdate as startdate
                INSERT INTO repair_parts (IdRepairParts, startdate, enddate, Parts_IdParts, Repair_IdRepair)
                VALUES (REPAIR_PARTS_SEQ.NEXTVAL, SYSDATE, NULL, v_parts_id, p_idrepair);
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            -- Insert a new entry in the repair_parts table with sysdate as startdate
            INSERT INTO repair_parts (IdRepairParts, startdate, enddate, Parts_IdParts, Repair_IdRepair)
            VALUES (REPAIR_PARTS_SEQ.NEXTVAL, SYSDATE, NULL, v_parts_id, p_idrepair);
        END;
	END change_parts;
	
	FUNCTION new_repair(
        p_repairdate IN repair.RepairDate%TYPE,
        p_issuedescription IN repair.IssueDescription%TYPE,
        p_isurgent IN repair.IsUrgent%TYPE,
		p_specialnotes IN repair.SpecialNotes%TYPE,
		p_partsreplaced IN parts.partsreplaced%TYPE
    ) RETURN INTEGER IS
		v_idrepair INTEGER;
	BEGIN
        BEGIN
            -- Check if the id already exists in the repair table
            SELECT IdRepair INTO v_idrepair
            FROM repair
            WHERE RepairDate = p_repairdate
            AND IssueDescription = p_issuedescription;

		-- If the IdRepair doesn't exist, create a new repair record with associated records
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            INSERT INTO repair (IdRepair, RepairDate, IssueDescription, IsUrgent, SpecialNotes)
        	VALUES (REPAIR_SEQ.NEXTVAL, p_repairdate, p_issuedescription, p_isurgent, p_specialnotes)
        	RETURNING IdRepair INTO v_idrepair;	
        END;

		-- Check if parts details are provided and not all fields are NULL
		IF p_partsreplaced IS NOT NULL THEN
            change_parts(v_idrepair, p_partsreplaced);
        END IF;
		RETURN v_idrepair;
    END new_repair;
END repair_pkg;
	
	
-- Create Repair_VIEW
CREATE OR REPLACE VIEW REPAIR_VIEW AS
SELECT 
    R.IdRepair,
    R.RepairDate,
    R.IssueDescription,
	R.IsUrgent,
	R.SpecialNotes,
    P.PartsReplaced AS current_PartsReplaced
FROM 
    repair R
JOIN 
    repair_parts RP ON R.IdRepair = RP.Repair_IdRepair
JOIN
    parts P ON RP.Parts_IdParts = P.IdParts
WHERE 
    RP.enddate IS NULL;

---create trigger
create or replace TRIGGER repair_view_trigger
INSTEAD OF INSERT OR UPDATE ON REPAIR_VIEW
FOR EACH ROW

DECLARE 
    p_repairdate repair.RepairDate%TYPE := :NEW.RepairDate;
    p_issuedescription repair.IssueDescription%TYPE := :NEW.IssueDescription;
	p_isurgent repair.IsUrgent%TYPE := :NEW.IsUrgent;
	p_specialnotes repair.SpecialNotes%TYPE := :NEW.SpecialNotes;
	p_partsreplaced parts.PartsReplaced%TYPE := :NEW.current_PartsReplaced;
    v_idrepair INTEGER;
BEGIN
    v_idrepair := repair_pkg.new_repair(p_repairdate, p_issuedescription, p_isurgent, p_specialnotes, p_partsreplaced);
END;

--delete trigger for repair_view
create or replace TRIGGER repair_view_dele_trigger
   INSTEAD OF DELETE ON REPAIR_VIEW
FOR EACH ROW

BEGIN 
   DELETE FROM repair_parts WHERE repair_idrepair = :OLD.idrepair;
   DELETE FROM repair WHERE IdRepair = :OLD.IdRepair;
END repair_view_dele_trigger;

------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- tuner_pkg package specification
CREATE or REPLACE PACKAGE tuner_pkg AS
    
	-- Procedure to change address
	PROCEDURE change_address(
		p_idtuner IN tuner_address.tuner_IdTuner%TYPE,
   		p_taddress IN address.taddress%TYPE
	);

    -- Function to create a new tuner record
    FUNCTION new_tuner(
        p_firstname IN tuner.FirstName%TYPE,
        p_lastname IN tuner.LastName%TYPE,
        p_email IN tuner.email%TYPE,
		p_contactnumber IN tuner.ContactNumber%TYPE,
		p_specialization IN tuner.specialization%TYPE,
		p_availability IN tuner.availability%TYPE,
		p_specialnotes IN tuner.specialnotes%TYPE,
		p_taddress IN address.taddress%TYPE
    ) RETURN INTEGER;

END tuner_pkg;
	
CREATE OR REPLACE PACKAGE BODY tuner_pkg AS

	PROCEDURE change_address(
		p_idtuner IN tuner_address.tuner_IdTuner%TYPE,
   		p_taddress IN address.taddress%TYPE
	) IS
		v_address_id address.IdTaddress%TYPE;
        v_tuner_address_id tuner_address.IdTunerAddress%TYPE;    
	BEGIN
        BEGIN
            -- Check if the address already exists in the address table
            SELECT IdTaddress INTO v_address_id
            FROM address
            WHERE TAddress = p_taddress;
        EXCEPTION
            -- If the address doesn't exist, insert a new address
            WHEN NO_DATA_FOUND THEN
            INSERT INTO address (IdTaddress, TAddress)
            VALUES (ADDRESS_SEQ.NEXTVAL, p_taddress)
            RETURNING IdTaddress INTO v_address_id;
        END;
		BEGIN
            -- Check if there's an existing address for the tuner in tuner_address table
            SELECT IdTunerAddress INTO v_tuner_address_id
            FROM tuner_address
            WHERE tuner_IdTuner = p_idtuner
            AND enddate IS NULL;
			
			-- Address exists for the tuner, update the current entry
            IF v_tuner_address_id IS NOT NULL THEN
                UPDATE tuner_address
                SET enddate = SYSDATE
                WHERE IdTunerAddress = v_tuner_address_id;
                
                -- Insert a new entry in the tuner_address table with sysdate as startdate
                INSERT INTO tuner_address (IdTunerAddress, startdate, enddate, Address_IdTAddress, Tuner_IdTuner)
                VALUES (TUNER_ADDRESS_SEQ.NEXTVAL, SYSDATE, NULL, v_address_id, p_idtuner);
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            -- Insert a new entry in the tuner_address table with sysdate as startdate
            INSERT INTO tuner_address (IdTunerAddress, startdate, enddate, Address_IdTAddress, Tuner_IdTuner)
            VALUES (TUNER_ADDRESS_SEQ.NEXTVAL, SYSDATE, NULL, v_address_id, p_idtuner);
        END;
	END change_address;
	
	FUNCTION new_tuner(
        p_firstname IN tuner.FirstName%TYPE,
        p_lastname IN tuner.LastName%TYPE,
        p_email IN tuner.email%TYPE,
		p_contactnumber IN tuner.ContactNumber%TYPE,
		p_specialization IN tuner.specialization%TYPE,
		p_availability IN tuner.availability%TYPE,
		p_specialnotes IN tuner.specialnotes%TYPE,
		p_taddress IN address.taddress%TYPE
    ) RETURN INTEGER IS
		v_idtuner INTEGER;
	BEGIN
        BEGIN
            -- Check if the id already exists in the tuner table
            SELECT IdTuner INTO v_idtuner
            FROM tuner
            WHERE FirstName = p_firstname
            AND LastName = p_lastname;

		-- If the IdTuner doesn't exist, create a new tuner record with associated records
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            INSERT INTO tuner (IdTuner, FirstName, LastName, email, ContactNumber, Specialization, Availability, SpecialNotes)
        	VALUES (TUNER_SEQ.NEXTVAL, p_firstname, p_lastname, p_email, p_contactnumber,p_specialization,p_availability,p_specialnotes)
        	RETURNING IdTuner INTO v_idtuner;	
        END;

		-- Check if address details are provided and not all fields are NULL
		IF p_taddress IS NOT NULL THEN
            change_address(v_idtuner, p_taddress);
        END IF;
		RETURN v_idtuner;
    END new_tuner;
END tuner_pkg;
	
-- Create Tuner_VIEW
CREATE OR REPLACE VIEW Tuner_VIEW AS
SELECT 
    T.IdTuner,
    T.FirstName,
	T.LastName,
    T.email,
	T.ContactNumber,
	T.Specialization,
	T.Availability,
	T.SpecialNotes,
    A.TAddress AS current_TAddress
FROM 
    tuner T
JOIN 
    tuner_address TA ON T.IdTuner = TA.Tuner_IdTuner
JOIN
    address A ON TA.Address_IdTAddress = A.IdTaddress
WHERE 
    TA.enddate IS NULL;

---create trigger
create or replace TRIGGER tuner_view_trigger
INSTEAD OF INSERT OR UPDATE ON TUNER_VIEW
FOR EACH ROW

DECLARE 
    p_firstname tuner.FirstName%TYPE := :NEW.FirstName;
	p_lastname tuner.LastName%TYPE := :NEW.LastName;
    p_email tuner.email%TYPE := :NEW.email;
	p_contactnumber tuner.ContactNumber%TYPE := :NEW.ContactNumber;
	p_specialization tuner.Specialization%TYPE := :NEW.Specialization;
	p_availability tuner.Availability%TYPE := :NEW.Availability;
    p_specialnotes tuner.SpecialNotes%TYPE := :NEW.SpecialNotes; 
	p_taddress address.TAddress%TYPE := :NEW.current_TAddress;
    v_idtuner INTEGER;
BEGIN
    v_idtuner := tuner_pkg.new_tuner(p_firstname, p_lastname, p_email, p_contactnumber, p_specialization, p_availability, p_specialnotes, p_taddress);
END;

--delete trigger for tuner_view
create or replace TRIGGER tuner_view_dele_trigger
   INSTEAD OF DELETE ON TUNER_VIEW
FOR EACH ROW

BEGIN 
   DELETE FROM tuner_address WHERE tuner_idtuner = :OLD.idtuner;
   DELETE FROM tuner WHERE idtuner = :OLD.idtuner;
END tuner_view_dele_trigger;



------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- individual_pkg package specification
CREATE or REPLACE PACKAGE individual_pkg AS
    
	-- Procedure to change ecname (emergency contact name)
	PROCEDURE change_ecname(
		p_idindividual IN individual_ecname.individual_IdIndividual%TYPE,
   		p_ecname IN ecname.ecname%TYPE,
		p_ecnumber IN ecname.ecnumber%TYPE
	);

    -- Function to create a new individual record
    FUNCTION new_individual(
        p_dateofbirth IN individual.DateOfBirth%TYPE,
        p_gender IN individual.gender%TYPE,
        p_specialnotes IN individual.SpecialNotes%TYPE,
		p_ecname IN ecname.ecname%TYPE,
		p_ecnumber IN ecname.ecnumber%TYPE
    ) RETURN INTEGER;

END individual_pkg;
	
CREATE OR REPLACE PACKAGE BODY individual_pkg AS

	PROCEDURE change_ecname(
		p_idindividual IN individual_ecname.individual_IdIndividual%TYPE,
   		p_ecname IN ecname.ecname%TYPE,
		p_ecnumber IN ecname.ecnumber%TYPE
	) IS
		v_ecname_id ecname.IdEcname%TYPE;
        v_individual_ecname_id individual_ecname.IdIndividualEcname%TYPE;    
	BEGIN
        BEGIN
            -- Check if the ecname and ecnumber already exist in the ecname table
            SELECT IdEcname INTO v_ecname_id
            FROM ecname
            WHERE ecname = p_ecname AND ecnumber = p_ecnumber;
        EXCEPTION
            -- If the ecname and ecnumber do not exist, insert a new ecname and ecnumber
            WHEN NO_DATA_FOUND THEN
            INSERT INTO ecname (IdEcname, ecname, ecnumber)
            VALUES (ECNAME_SEQ.NEXTVAL, p_ecname, p_ecnumber)
            RETURNING IdEcname INTO v_ecname_id;
        END;
		BEGIN
            -- Check if there's an existing ecname and ecnumber for the individual in individual_ecname table
            SELECT IdIndividualEcname INTO v_individual_ecname_id
            FROM individual_ecname
            WHERE individual_IdIndividual = p_idindividual
            AND enddate IS NULL;
			
			-- Address exists for the individual, update the current entry which is "update" 
            IF v_individual_ecname_id IS NOT NULL THEN
                UPDATE individual_ecname
                SET enddate = SYSDATE
                WHERE IdIndividualEcname = v_individual_ecname_id;
                
                -- Insert a new entry in the individual_ecname table with sysdate as startdate
                INSERT INTO individual_ecname (IdIndividualEcname, startdate, enddate, Ecname_IdEcname, individual_IdIndividual)
                VALUES (INDIVIDUAL_ECNAME_SEQ.NEXTVAL, SYSDATE, NULL, v_ecname_id, p_idindividual);
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            -- Insert a new entry in the individual_ecname table with sysdate as startdate
            INSERT INTO individual_ecname (IdIndividualEcname, startdate, enddate, Ecname_IdEcname, individual_IdIndividual)
            VALUES (INDIVIDUAL_ECNAME_SEQ.NEXTVAL, SYSDATE, NULL, v_ecname_id, p_idindividual);
        END;
	END change_ecname;
	
	FUNCTION new_individual(
        p_dateofbirth IN individual.DateOfBirth%TYPE,
        p_gender IN individual.gender%TYPE,
 		p_specialnotes IN individual.SpecialNotes%TYPE,
		p_ecname IN ecname.ecname%TYPE,
		p_ecnumber IN ecname.ecnumber%TYPE
    ) RETURN INTEGER IS
		v_idindividual INTEGER;
	BEGIN
        BEGIN
            -- Check if the id already exists in the individual table
            SELECT IdIndividual INTO v_idindividual
            FROM individual
            WHERE DateOfBirth = p_dateofbirth
            AND gender = p_gender;

		-- If the IdIndividual doesn't exist, create a new individual record with associated records
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            INSERT INTO individual (IdIndividual, DateOfBirth, gender, SpecialNotes)
        	VALUES (INDIVIDUAL_SEQ.NEXTVAL, p_dateofbirth, p_gender, p_specialnotes)
        	RETURNING IdIndividual INTO v_idindividual;	
        END;

		-- Check if ecname detail is provided and not all fields are NULL
		IF p_ecname IS NOT NULL THEN
            change_ecname(v_idindividual, p_ecname, p_ecnumber);
        END IF;
		RETURN v_idindividual;
    END new_individual;
END individual_pkg;
	
-- Create INDIVIDUAL_VIEW
CREATE OR REPLACE VIEW Individual_VIEW AS
SELECT 
    I.IdIndividual,
    I.DateOfBirth,
	I.gender,
    I.SpecialNotes,
	E.ecname AS current_ecname,
	E.ecnumber AS current_ecnumber
FROM 
    individual I
JOIN 
    individual_ecname IE ON I.IdIndividual = IE.individual_IdIndividual
JOIN
    ecname E ON IE.Ecname_IdEcname = E.IdEcname
WHERE 
    IE.enddate IS NULL;

---create trigger
create or replace TRIGGER individual_view_trigger
INSTEAD OF INSERT OR UPDATE ON INDIVIDUAL_VIEW
FOR EACH ROW

DECLARE 
    p_dateofbirth individual.DateOfBirth%TYPE := :NEW.DateOfBirth;
	p_gender individual.gender%TYPE := :NEW.gender;
    p_specialnotes individual.SpecialNotes%TYPE := :NEW.SpecialNotes;
	p_ecname ecname.ecname%TYPE := :NEW.current_ecname;
	p_ecnumber ecname.ecnumber%TYPE := :NEW.current_ecnumber;
    v_idindividual INTEGER;
BEGIN
    v_idindividual := individual_pkg.new_individual(p_dateofbirth, p_gender, p_specialnotes, p_ecname, p_ecnumber);
END;

--delete trigger for individual_view
create or replace TRIGGER individual_view_dele_trigger
   INSTEAD OF DELETE ON INDIVIDUAL_VIEW
FOR EACH ROW

BEGIN 
   DELETE FROM individual_ecname WHERE individual_IdIndividual = :OLD.IdIndividual;
   DELETE FROM individual WHERE IdIndividual = :OLD.IdIndividual;
END individual_view_dele_trigger;
      