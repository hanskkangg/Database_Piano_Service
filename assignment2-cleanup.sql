--cleanup for assignment2

DROP USER kangUser_db CASCADE;
DROP USER testUser;
DROP ROLE applicationAdmin;
DROP ROLE applicationUser;
DROP TABLESPACE assignment2 INCLUDING CONTENTS AND DATAFILES;

-- End of File