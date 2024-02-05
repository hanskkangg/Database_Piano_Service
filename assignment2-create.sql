-- 
-- ORACLE application database and associated users creation script for assignment2
--
-- Created by:  Hans Kang
--
-- should be run while connected as 'sys as sysdba'
--

--Version: V3?
---Date and time: 2023-12-03, 11:20am
--change: ECName table, individual table, 

-- Create STORAGE
CREATE TABLESPACE assignment2
  DATAFILE 'assignment2.dat' SIZE 40M 
  ONLINE; 
  
-- Create Users
CREATE USER hanskUser IDENTIFIED BY hanskPassword ACCOUNT UNLOCK
	DEFAULT TABLESPACE assignment2
	QUOTA 20M ON assignment2;
	
CREATE USER testUser IDENTIFIED BY testPassword ACCOUNT UNLOCK
	DEFAULT TABLESPACE assignment2
	QUOTA 5M ON assignment2;
	
-- Create ROLES
CREATE ROLE applicationAdmin;
CREATE ROLE applicationUser;

-- Grant PRIVILEGES
GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE TRIGGER, CREATE PROCEDURE TO applicationAdmin;
GRANT CONNECT, RESOURCE TO applicationUser;

GRANT applicationAdmin TO hanskUser;
GRANT applicationUser TO testUser;

-- NOW we can connect as the applicationAdmin and create the stored procedures, tables, and triggers

CONNECT hanskUser/hanskPassword;

--Create tables (11 original tables and 

CREATE TABLE customer (
  IdCustomer int NOT NULL,
  FirstName nvarchar2(20) NULL,
  LastName nvarchar2(20) NULL,
  ContactNumber varchar2(15) NULL,
  Email nvarchar2(30) NULL,
  Address nvarchar2(40) NULL,
  CompanyName nvarchar2(30) NULL,
  PRIMARY KEY (IdCustomer)
);

INSERT INTO customer VALUES (1,'Douglas','Smith','613-678-2578','douglass@google.com', '200 kent street,Ottawa, On, K3J9H2',null);
INSERT INTO customer VALUES (2,'Tom','Terhune','613-555-2456','tomt@google.com', '88 Strandherd Ave.,Ottawa, On, K2J0P2',null);
INSERT INTO customer VALUES (3,null, null,'613-888-1234','hr@stars.com', '567 Kent street,Ottawa, On, P3Y6H7','Stars');
INSERT INTO customer VALUES (4,null, null,'613-555-3456','hr@climbgym.com', '308 March Rd,Ottawa, On, M1T3Y6','Climbgym');
INSERT INTO customer VALUES (5,null, null,'613-333-8888','hr@pandacanoe.com', '258 Pinetrail Crescent, On, H6R3B4','Pandacanoe');
INSERT INTO customer VALUES (6,'Khushi','White','613-348-5890','kwhite@yahoo.com', '158 March Rd,Ottawa, On, F5J8H4',null);
INSERT INTO customer VALUES (7,'Daniel','Yang','416-290-2578','dyang@hotmail.com', '450 Carling avenue,Ottawa, On, P6L3W1',null);
INSERT INTO customer VALUES (8,'Chris','Hu','456-583-5090','chu@google.com', '333 kingston Road,Ottawa, On, P8T6Q3',null);
INSERT INTO customer VALUES (9,'Anna','Chen','578-873-7490','achen@yahoo.com', '420 Wellington street,Ottawa, On, G3T7W9',null);
INSERT INTO customer VALUES (10,'Jennifer','Zhang','416-777-6666','jzhang@google.com', '360 Greenbank avenue,Ottawa, On, B9D7S5',null);


CREATE TABLE ECName (
   IdEcname int NOT NULL,
   EmergencyContactFistName nvarchar2(50) NULL,
   EmergencyContactLastName nvarchar2(50) NULL,
   PRIMARY KEY (IdEcname)
);

CREATE TABLE individual (
  IdIndividual int NOT NULL,
  Customer_IdCustomer int NOT NULL,
  DateOfBirth date NULL,
  Gender nvarchar2(10) NULL,
  EmergencyContactNumber nvarchar2(15) NULL,
  SpecialNotes nvarchar2(100) NULL,
  PRIMARY KEY (IdIndividual),
  CONSTRAINT fk_i_c_c1 FOREIGN KEY (Customer_IdCustomer) REFERENCES customer (IdCustomer)
);

CREATE TABLE individual_ECName (
  IdIndividualEcname int NOT NULL,
  startdate timestamp NOT NULL,
  enddate timestamp DEFAULT NULL,
  Ecname_IdEcname int NOT NULL,
  Individual_IdIndividual int NOT NULL,
  PRIMARY KEY (IdIndividualEcname),
  CONSTRAINT fk_i_e_e1 FOREIGN KEY (Ecname_IdEcname) REFERENCES ECName (IdEcname),
  CONSTRAINT fk_i_e_c1 FOREIGN KEY (Individual_IdIndividual) REFERENCES individual(IdIndividual)  
);


CREATE TABLE company (
  IdCompany int NOT NULL,
  Customer_IdCustomer int NOT NULL,
  RegistrationNumber nvarchar2(15) NULL,
  ContactPerson nvarchar2(50) NULL,
  Website nvarchar2(100) NULL,
  SpecialNotes nvarchar2(100) NULL,
  PRIMARY KEY (IdCompany),
  CONSTRAINT fk_c_c_c1 FOREIGN KEY (Customer_IdCustomer) REFERENCES customer(IdCustomer)
);

CREATE TABLE tuner(
  IdTuner int NOT NULL,
  FirstName nvarchar2(20) NULL,
  LastName nvarchar2(20) NULL,
  Email varchar2(50) NULL,
  ContactNumber nvarchar2(15) NULL,
  Specialization nvarchar2(50) NULL,
  Availability nvarchar2(100) NULL,
  SpecialNotes nvarchar2(100) NULL,
  PRIMARY KEY (IdTuner)  
);

CREATE TABLE address(
  IdTaddress int NOT NULL,
  Taddress nvarchar2(100) NULL,
  PRIMARY KEY (IdTaddress)  
);

CREATE TABLE tuner_address(
  IdTunerAddress int NOT NULL,
  startdate timestamp NOT NULL,
  enddate timestamp DEFAULT NULL,
  Address_IdTaddress int NOT NULL,
  Tuner_IdTuner int NOT NULL,
  PRIMARY KEY (IdTunerAddress),
  CONSTRAINT fk_t_a_al FOREIGN KEY (Address_IdTaddress) REFERENCES address(IdTaddress),
  CONSTRAINT fk_t_t_tl FOREIGN KEY (Tuner_IdTuner) REFERENCES tuner(IdTuner)  
);

CREATE TABLE service(
  IdService int NOT NULL,
  ServiceName nvarchar2(50) NULL,
  Description nvarchar2(100) NULL,
  Duration int NULL,
  Cost decimal(10,2) NULL,
  PRIMARY KEY (IdService) 
);

CREATE TABLE tuning(
  IdTuning int NOT NULL,
  TuningDate date NULL,
  PianoModel nvarchar2(50) NULL,
  PianoSerialNumber nvarchar2(100) NULL,
  SpecialNotes nvarchar2(100) NULL,
  Service_IdService int NULL,
  PRIMARY KEY (IdTuning), 
  CONSTRAINT fk_t_s_s1 FOREIGN KEY (Service_IdService) REFERENCES service(IdService)
);

CREATE TABLE invoice(
  IdInvoice int NOT NULL,
  TotalAmount decimal(10,2) NULL,
  DueDate date NULL,
  InvoiceNumber nvarchar2(20) NULL,
  InvoiceDate date NULL,
  InvoiceStatus nvarchar2(20) NULL,
  PRIMARY KEY (IdInvoice) 
);

CREATE TABLE repair(
  IdRepair int NOT NULL,
  RepairDate date NULL,
  IssueDescription nvarchar2(100) NULL,
  IsUrgent NUMBER(1) NULL,
  SpecialNotes nvarchar2(100) NULL,
  Service_IdService int NULL,
  PRIMARY KEY (IdRepair), 
  CONSTRAINT fk_r_s_s1 FOREIGN KEY (Service_IdService) REFERENCES service(IdService)
);

CREATE TABLE parts(
  IdParts int NOT NULL,
  PartsReplaced nvarchar2(100) NULL,
  PRIMARY KEY (IdParts)  
);

CREATE TABLE repair_parts(
  IdRepairParts int NOT NULL,
  startdate timestamp NOT NULL,
  enddate timestamp DEFAULT NULL,
  Parts_IdParts int NOT NULL,
  Repair_IdRepair int NOT NULL,
  PRIMARY KEY (IdRepairParts),
  CONSTRAINT fk_r_p_p1 FOREIGN KEY (Parts_IdParts) REFERENCES parts(IdParts),
  CONSTRAINT fk_r_r_r1 FOREIGN KEY (Repair_IdRepair) REFERENCES repair(IdRepair)  
);


CREATE TABLE payment(
  IdPayment int NOT NULL,
  PaymentAmount decimal(10,2) NULL,
  PaymentDate date NULL,
  PaymentMethod nvarchar2(20) NULL,
  Status nvarchar2(10) NULL,
  Invoice_IdInvoice int NOT NULL,
  SpecialNotes nvarchar2(100) NULL,
  PRIMARY KEY (IdPayment), 
  CONSTRAINT fk_p_i_i1 FOREIGN KEY (Invoice_IdInvoice) REFERENCES invoice(IdInvoice)
);

CREATE TABLE appointment (
  IdAppointment int NOT NULL,
  AppointmentType nvarchar2(20) NULL,
  StartTime date NULL,
  Duration int NULL,
  Status nvarchar2(20) NULL,
  SpecialNotes nvarchar2(100) NULL,
  Customer_IdCustomer int NOT NULL,
  Tuner_IdTuner int NOT NULL,
  Invoice_IdInvoice int NOT NULL,
  PRIMARY KEY (IdAppointment),
  CONSTRAINT fk_a_c_c1 FOREIGN KEY (Customer_IdCustomer) REFERENCES customer(IdCustomer),
  CONSTRAINT fk_a_t_t1 FOREIGN KEY (Tuner_IdTuner) REFERENCES tuner(IdTuner),
  CONSTRAINT fk_a_i_i1 FOREIGN KEY (Invoice_IdInvoice) REFERENCES invoice(IdInvoice)
);


CREATE TABLE connectionTable(
  IdConnection int NOT NULL,
  Appointment_IdAppointment int NOT NULL,
  Service_IdService int NOT NULL,
  PRIMARY KEY (IdConnection), 
  CONSTRAINT fk_c_a_a1 FOREIGN KEY (Service_IdService) REFERENCES service(IdService),
  CONSTRAINT fk_c_s_s1 FOREIGN KEY (Appointment_IdAppointment) REFERENCES appointment(IdAppointment)
);

--Inject data!!!

INSERT INTO ECName VALUES (1, 'Roberto', 'Smith');
INSERT INTO ECName VALUES (2, 'Kamila', 'Yang');

-- individual table.
INSERT INTO individual VALUES (1, 1, TO_DATE('1990-01-01', 'YYYY-MM-DD'), 'Male', '613-111-2222', 'Notes for individual 1');
INSERT INTO individual VALUES (2, 2, TO_DATE('1985-05-15', 'YYYY-MM-DD'), 'Female', '613-888-6666','Notes for individual 2');
-- 
INSERT INTO individual_ECName VALUES (1, CURRENT_TIMESTAMP, NULL, 1, 1);
INSERT INTO individual_ECName VALUES (2, CURRENT_TIMESTAMP, NULL, 2, 2);
-- 
INSERT INTO company VALUES (1, 1, 'Reg123', 'Shakira', 'www.company1.com', 'Notes for company 1');
INSERT INTO company VALUES (2, 2, 'Reg456', 'Neils Bohr', 'www.company2.com', 'Notes for company 2');
-- 
INSERT INTO tuner VALUES (1, 'John', 'Doe', 'john.doe@example.com', '613-555-1111', 'Piano Tuner', 'Monday and Wednesday', 'Notes for tuner 1');
INSERT INTO tuner VALUES (2, 'Jane', 'Smith', 'jane.smith@example.com', '613-555-2222', 'Guitar Tuner', 'Tuesday and Thursday', 'Notes for tuner 2');
-- 
INSERT INTO address VALUES (1, '123 Main St, City');
INSERT INTO address VALUES (2, '456 Oak St, City');
-- 
INSERT INTO tuner_address VALUES (1, CURRENT_TIMESTAMP, NULL, 1, 1);
INSERT INTO tuner_address VALUES (2, CURRENT_TIMESTAMP, NULL, 2, 2);
-- 
INSERT INTO service VALUES (1, 'Tuning Service', 'Piano tuning service', 60, 100.00);
INSERT INTO service VALUES (2, 'Repair Service', 'Instrument repair service', 120, 150.00);
-- 
INSERT INTO tuning VALUES (1, TO_DATE('2023-01-15', 'YYYY-MM-DD'), 'Grand Piano', 'SN123', 'Notes for tuning 1', 1);
INSERT INTO tuning VALUES (2, TO_DATE('2023-02-01', 'YYYY-MM-DD'), 'Upright Piano', 'SN456', 'Notes for tuning 2', 2);
-- 
INSERT INTO invoice VALUES (1, 100.00, TO_DATE('2023-01-20', 'YYYY-MM-DD'), 'INV001', TO_DATE('2023-01-15', 'YYYY-MM-DD'), 'Paid');
INSERT INTO invoice VALUES (2, 150.00, TO_DATE('2023-02-10', 'YYYY-MM-DD'), 'INV002', TO_DATE('2023-02-01', 'YYYY-MM-DD'), 'Pending');
-- 
INSERT INTO repair VALUES (1, TO_DATE('2023-03-01', 'YYYY-MM-DD'), 'Broken string', 1, 'Notes for repair 1', 2);
INSERT INTO repair VALUES (2, TO_DATE('2023-04-01', 'YYYY-MM-DD'), 'Sticky keys',  0, 'Notes for repair 2', 1);
--
INSERT INTO parts VALUES (1, 'Strings');
INSERT INTO parts VALUES (2, 'Keys');
--
INSERT INTO repair_parts VALUES (1, CURRENT_TIMESTAMP, NULL, 1, 1);
INSERT INTO repair_parts VALUES (2, CURRENT_TIMESTAMP, NULL, 2, 2);
-- 
INSERT INTO payment VALUES (1, 100.00, TO_DATE('2023-01-25', 'YYYY-MM-DD'), 'Credit Card', 'Paid', 1, 'Notes for payment 1');
INSERT INTO payment VALUES (2, 75.00, TO_DATE('2023-02-15', 'YYYY-MM-DD'), 'PayPal', 'Pending', 2, 'Notes for payment 2');
-- 
INSERT INTO appointment VALUES (1, 'Tuning', TO_DATE('2023-01-10', 'YYYY-MM-DD'), 60, 'Scheduled', 'Notes for appointment 1', 1, 1, 1);
INSERT INTO appointment VALUES (2, 'Repair', TO_DATE('2023-02-05', 'YYYY-MM-DD'), 120, 'Completed', 'Notes for appointment 2', 2, 2, 2); 
--
INSERT INTO connectionTable VALUES (1, 1, 1);
INSERT INTO connectionTable VALUES (2, 2, 2);

COMMIT;

-- End of File
