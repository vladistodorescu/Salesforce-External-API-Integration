@isTest
private class TechTrekBatchTest {

    @isTest
    static void testBatchSuccess(){
        Test.setMock(HttpCalloutMock.class, new TechTrekApiMock(200, 200, 200));

        Test.startTest();
            Database.executeBatch(new TechTrekBatch(), 1);
        Test.stopTest();

        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'Global Tech Industries'];
        List<Contact> contacts = [SELECT Id FROM Contact WHERE CNP__c = '1980512123456'];
        List<Case> cases = [SELECT Id FROM Case WHERE Reference_Number__c = 'SR-2026-1001'];

        Assert.isFalse(accounts.isEmpty(), 'Accounts should have been inserted');
        Assert.isFalse(contacts.isEmpty(), 'Contacts should have been inserted');
        Assert.isFalse(cases.isEmpty(), 'Cases should have been inserted');

        List<Integration_Log__c> logs = [SELECT Id, Endpoint__c, Error_Type__c, Error_Message__c FROM Integration_Log__c];
        Assert.isTrue(logs.isEmpty(), 'No error logs should exist: ' + JSON.serialize(logs));
    }

    @isTest
    static void testBatchHttpError(){
        Test.setMock(HttpCalloutMock.class, new TechTrekApiMock(400, 400, 400));

        Test.startTest();
            Database.executeBatch(new TechTrekBatch(), 1);
        Test.stopTest();

        List<Integration_Log__c> logs = [SELECT Id, Error_Type__c, Endpoint__c FROM Integration_Log__c WHERE Error_Type__c = 'HTTP'];
        Assert.isFalse(logs.isEmpty(), 'HTTP error logs should have been created');

        List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Global Tech Industries'];
        List<Contact> contacts = [SELECT Id FROM Contact WHERE CNP__c = '1980512123456'];
        List<Case> cases = [SELECT Id FROM Case WHERE Reference_Number__c = 'SR-2026-1001'];

        Assert.isTrue(accounts.isEmpty(), 'No accounts should have been inserted on HTTP error');
        Assert.isTrue(contacts.isEmpty(), 'No contacts should have been inserted on HTTP error');
        Assert.isTrue(cases.isEmpty(), 'No cases should have been inserted on HTTP error');
    }

    @isTest
    static void testBatchPartialHttpError(){
        Test.setMock(HttpCalloutMock.class, new TechTrekApiMock(200, 400, 400));

        Test.startTest();
            Database.executeBatch(new TechTrekBatch(), 1);
        Test.stopTest();

        List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Global Tech Industries'];
        Assert.isFalse(accounts.isEmpty(), 'Accounts should have been inserted');

        List<Contact> contacts = [SELECT Id FROM Contact WHERE CNP__c = '1980512123456'];
        Assert.isTrue(contacts.isEmpty(), 'No contacts should have been inserted');

        List<Integration_Log__c> logs = [SELECT Id FROM Integration_Log__c WHERE Error_Type__c = 'HTTP'];
        Assert.isFalse(logs.isEmpty(), 'HTTP error logs should have been created for failed endpoints');
    }

    @isTest
    static void testBatchSchedulable(){
        Test.setMock(HttpCalloutMock.class, new TechTrekApiMock(200, 200, 200));

        Test.startTest();
            String jobId = System.schedule('TechTrekBatch Test', '0 0 2 * * ?', new TechTrekBatch());
        Test.stopTest();

        List<CronTrigger> scheduledJobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE Id = :jobId];
        Assert.isFalse(scheduledJobs.isEmpty(), 'Batch should be scheduled');
        Assert.areEqual('TechTrekBatch Test', scheduledJobs[0].CronJobDetail.Name, 'Job name should match');
    }

    @isTest
    static void testBatchHttpError_LogFields(){
        Test.setMock(HttpCalloutMock.class, new TechTrekApiMock(400, 400, 400));

        Test.startTest();
            Database.executeBatch(new TechTrekBatch(), 1);
        Test.stopTest();

        List<Integration_Log__c> accountLogs = [
            SELECT Id, Endpoint__c, Error_Type__c, Error_Message__c, Status_Code__c, Execution_Time__c
            FROM Integration_Log__c
            WHERE Endpoint__c = '/accountEndpoint' AND Error_Type__c = 'HTTP'
        ];
        Assert.isFalse(accountLogs.isEmpty(), 'Account HTTP log should exist');
        Assert.areEqual('/accountEndpoint', accountLogs[0].Endpoint__c, 'Endpoint should match');
        Assert.areEqual('HTTP', accountLogs[0].Error_Type__c, 'Error type should be HTTP');
        Assert.areEqual(400, accountLogs[0].Status_Code__c, 'Status code should be 400');
        Assert.isNotNull(accountLogs[0].Execution_Time__c, 'Execution time should be set');

        List<Integration_Log__c> contactLogs = [
            SELECT Id, Endpoint__c, Error_Type__c, Status_Code__c
            FROM Integration_Log__c
            WHERE Endpoint__c = '/contactEndpoint' AND Error_Type__c = 'HTTP'
        ];
        Assert.isFalse(contactLogs.isEmpty(), 'Contact HTTP log should exist');
        Assert.areEqual(400, contactLogs[0].Status_Code__c, 'Status code should be 400');

        List<Integration_Log__c> caseLogs = [
            SELECT Id, Endpoint__c, Error_Type__c, Status_Code__c
            FROM Integration_Log__c
            WHERE Endpoint__c = '/caseEndpoint' AND Error_Type__c = 'HTTP'
        ];
        Assert.isFalse(caseLogs.isEmpty(), 'Case HTTP log should exist');
        Assert.areEqual(400, caseLogs[0].Status_Code__c, 'Status code should be 400');
    }

    @isTest
    static void testBatchApexError_LogCreated(){
        // Null mock → callout throws CalloutException → APEX error log created
        Test.setMock(HttpCalloutMock.class, new TechTrekApiMock(null, null, null));

        Test.startTest();
            Database.executeBatch(new TechTrekBatch(), 1);
        Test.stopTest();

        List<Integration_Log__c> logs = [
            SELECT Id, Endpoint__c, Error_Type__c, Error_Message__c, Execution_Time__c
            FROM Integration_Log__c
            WHERE Error_Type__c = 'APEX' OR Error_Type__c = 'HTTP'
        ];
        Assert.isFalse(logs.isEmpty(), 'Error logs should have been created');
        Assert.isNotNull(logs[0].Error_Message__c, 'Error message should be populated');
        Assert.isNotNull(logs[0].Execution_Time__c, 'Execution time should be populated');
    }   

    @isTest
    static void testBatchSuccess_NoLogsCreated(){
        Test.setMock(HttpCalloutMock.class, new TechTrekApiMock(200, 200, 200));

        Test.startTest();
            Database.executeBatch(new TechTrekBatch(), 1);
        Test.stopTest();

        List<Integration_Log__c> logs = [SELECT Id FROM Integration_Log__c];
        Assert.isTrue(logs.isEmpty(), 'No logs should be created on a fully successful run');
    }

    @isTest
    static void testBatchPartialHttpError_LogFields(){
        Test.setMock(HttpCalloutMock.class, new TechTrekApiMock(200, 400, 400));

        Test.startTest();
            Database.executeBatch(new TechTrekBatch(), 1);
        Test.stopTest();

        // Account succeeded — no account log
        List<Integration_Log__c> accountLogs = [
            SELECT Id FROM Integration_Log__c
            WHERE Endpoint__c = '/accountEndpoint'
        ];
        Assert.isTrue(accountLogs.isEmpty(), 'No account error log should exist');

        // Contact failed — log should exist with correct fields
        List<Integration_Log__c> contactLogs = [
            SELECT Id, Endpoint__c, Error_Type__c, Status_Code__c, Request_Type__c
            FROM Integration_Log__c
            WHERE Endpoint__c = '/contactEndpoint' AND Error_Type__c = 'HTTP'
        ];
        Assert.isFalse(contactLogs.isEmpty(), 'Contact HTTP log should exist');
        Assert.areEqual(400, contactLogs[0].Status_Code__c, 'Status code should be 400');
        Assert.areEqual('0', contactLogs[0].Request_Type__c, 'Request type should be 0');

        // Case failed — log should exist
        List<Integration_Log__c> caseLogs = [
            SELECT Id, Error_Type__c
            FROM Integration_Log__c
            WHERE Endpoint__c = '/caseEndpoint' AND Error_Type__c = 'HTTP'
        ];
        Assert.isFalse(caseLogs.isEmpty(), 'Case HTTP log should exist');
    }
}
