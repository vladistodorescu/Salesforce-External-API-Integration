@isTest
private class RecordServiceTest {

    @TestSetup
    static void setupTestData(){
        // Pre-existing Account — will hit the UPDATE path
        Account existingAcc = new Account();
        existingAcc.Name = 'Global Tech Industries';
        insert existingAcc;

        // Pre-existing Contact — will hit the UPDATE path
        Contact existingCon = new Contact();
        existingCon.FirstName = 'Andrei';
        existingCon.LastName = 'Popescu';
        existingCon.CNP__c = '1980512123456';
        insert existingCon;

        // Pre-existing Case — will hit the UPDATE path
        Case existingCase = new Case();
        existingCase.Reference_Number__c = 'SR-2026-1001';
        insert existingCase;
    }

    // ── upsertAccounts ────────────────────────────────────────────────────────

    @isTest
    static void testUpsertAccounts_InsertPath(){
        // Account with a name that doesn't exist in the org
        String body = '{'
            + '"organization": {'
            +   '"identity": {'
            +     '"registeredName": "New Test Company",'
            +     '"taxIdentifier": "RO99999999"'
            +   '},'
            +   '"classification": {'
            +     '"sector": "Technology",'
            +     '"marketSegment": "B2C"'
            +   '},'
            +   '"financialOverview": {'
            +     '"annualTurnover": 1000000,'
            +     '"fiscalCurrency": "RON",'
            +     '"fiscalYear": 2026'
            +   '},'
            +   '"workforce": {'
            +     '"employeeCount": 50,'
            +     '"departments": ["IT", "HR"]'
            +   '},'
            +   '"communicationChannels": {'
            +     '"primaryPhone": "+40 21 000 0000",'
            +     '"website": "https://newtest.ro"'
            +   '},'
            +   '"locations": {'
            +     '"headOffice": {'
            +       '"streetLine": "Str. Test 1",'
            +       '"cityName": "Cluj",'
            +       '"postalCode": "400000",'
            +       '"countryName": "Romania"'
            +     '}'
            +   '}'
            + '}'
            + '}';

        TechTrekApiService.ApiResponse response = new TechTrekApiService.ApiResponse();
        response.statusCode = 200;
        response.body = body;

        Test.startTest();
            RecordService.upsertAccounts(new List<TechTrekApiService.ApiResponse>{ response });
        Test.stopTest();

        Account inserted = [SELECT Id, Name, Industry, Phone FROM Account WHERE Name = 'New Test Company'];
        Assert.areEqual('Technology', inserted.Industry, 'Industry should be Technology');
        Assert.areEqual('+40 21 000 0000', inserted.Phone, 'Phone should match');
    }

    @isTest
    static void testUpsertAccounts_UpdatePath(){
        // Same name as the one inserted in @TestSetup → hits UPDATE branch
        String body = '{'
            + '"organization": {'
            +   '"identity": {'
            +     '"registeredName": "Global Tech Industries",'
            +     '"taxIdentifier": "RO12345678"'
            +   '},'
            +   '"classification": {'
            +     '"sector": "Manufacturing",'
            +     '"marketSegment": "B2B"'
            +   '},'
            +   '"financialOverview": {'
            +     '"annualTurnover": 3200000,'
            +     '"fiscalCurrency": "EUR",'
            +     '"fiscalYear": 2025'
            +   '},'
            +   '"workforce": {'
            +     '"employeeCount": 240,'
            +     '"departments": ["Production", "Logistics", "Sales"]'
            +   '},'
            +   '"communicationChannels": {'
            +     '"primaryPhone": "+40 21 555 7788",'
            +     '"website": "https://globaltech.ro"'
            +   '},'
            +   '"locations": {'
            +     '"headOffice": {'
            +       '"streetLine": "Str. Fabricii 12",'
            +       '"cityName": "Timisoara",'
            +       '"postalCode": "300123",'
            +       '"countryName": "Romania"'
            +     '}'
            +   '}'
            + '}'
            + '}';

        TechTrekApiService.ApiResponse response = new TechTrekApiService.ApiResponse();
        response.statusCode = 200;
        response.body = body;

        Test.startTest();
            RecordService.upsertAccounts(new List<TechTrekApiService.ApiResponse>{ response });
        Test.stopTest();

        Account updated = [SELECT Id, Name, Sic, Industry, BillingCity FROM Account WHERE Name = 'Global Tech Industries'];
        Assert.areEqual('RO12345678', updated.Sic, 'Sic should be updated');
        Assert.areEqual('Manufacturing', updated.Industry, 'Industry should be updated');
        Assert.areEqual('Timisoara', updated.BillingCity, 'BillingCity should be updated');
    }

    @isTest
    static void testUpsertAccounts_BadJson(){
        TechTrekApiService.ApiResponse response = new TechTrekApiService.ApiResponse();
        response.statusCode = 200;
        response.body = '{"bad": "json"}';

        Test.startTest();
            RecordService.upsertAccounts(new List<TechTrekApiService.ApiResponse>{ response });
        Test.stopTest();

        List<Integration_Log__c> logs = [SELECT Id, Error_Type__c FROM Integration_Log__c WHERE Error_Type__c = 'JSON'];
        Assert.isFalse(logs.isEmpty(), 'A JSON error log should have been created');
    }

    @isTest
    static void testUpsertAccounts_EmptyList(){
        Test.startTest();
            try {
                RecordService.upsertAccounts(new List<TechTrekApiService.ApiResponse>());
                Assert.fail('Should have thrown AuraHandledException');
            }
            catch (AuraHandledException e){
                Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
            }
        Test.stopTest();
    }

    // ── upsertContacts ────────────────────────────────────────────────────────

    @isTest
    static void testUpsertContacts_InsertPath(){
        String body = '{'
            + '"personProfile": {'
            +   '"identity": {'
            +     '"givenName": "Ion",'
            +     '"familyName": "Ionescu",'
            +     '"personalIdentifier": "1990101987654"'
            +   '},'
            +   '"professionalDetails": {'
            +     '"jobTitle": "Developer",'
            +     '"division": "IT"'
            +   '},'
            +   '"communication": {'
            +     '"emails": [{'
            +       '"emailAddress": "ion.ionescu@test.ro",'
            +       '"type": "Work",'
            +       '"isPrimary": true'
            +     '}],'
            +     '"phones": [{'
            +       '"phoneNumber": "+40 722 000 000",'
            +       '"type": "Mobile"'
            +     '}]'
            +   '},'
            +   '"residence": {'
            +     '"cityName": "Cluj",'
            +     '"countryName": "Romania"'
            +   '}'
            + '}'
            + '}';

        TechTrekApiService.ApiResponse response = new TechTrekApiService.ApiResponse();
        response.statusCode = 200;
        response.body = body;

        Test.startTest();
            RecordService.upsertContacts(new List<TechTrekApiService.ApiResponse>{ response });
        Test.stopTest();

        Contact inserted = [SELECT Id, FirstName, LastName, CNP__c, Email, MailingCity FROM Contact WHERE CNP__c = '1990101987654'];
        Assert.areEqual('Ion', inserted.FirstName, 'FirstName should match');
        Assert.areEqual('Ionescu', inserted.LastName, 'LastName should match');
        Assert.areEqual('ion.ionescu@test.ro', inserted.Email, 'Email should match');
        Assert.areEqual('Cluj', inserted.MailingCity, 'MailingCity should match');
    }

    @isTest
    static void testUpsertContacts_UpdatePath(){
        // Same CNP as the one inserted in @TestSetup → hits UPDATE branch
        String body = '{'
            + '"personProfile": {'
            +   '"identity": {'
            +     '"givenName": "Andrei",'
            +     '"familyName": "Popescu",'
            +     '"personalIdentifier": "1980512123456"'
            +   '},'
            +   '"professionalDetails": {'
            +     '"jobTitle": "Sales Manager",'
            +     '"division": "Sales"'
            +   '},'
            +   '"communication": {'
            +     '"emails": [{'
            +       '"emailAddress": "andrei.popescu@globaltech.ro",'
            +       '"type": "Work",'
            +       '"isPrimary": true'
            +     '}],'
            +     '"phones": [{'
            +       '"phoneNumber": "+40 722 111 222",'
            +       '"type": "Mobile"'
            +     '}]'
            +   '},'
            +   '"residence": {'
            +     '"cityName": "Timisoara",'
            +     '"countryName": "Romania"'
            +   '}'
            + '}'
            + '}';

        TechTrekApiService.ApiResponse response = new TechTrekApiService.ApiResponse();
        response.statusCode = 200;
        response.body = body;

        Test.startTest();
            RecordService.upsertContacts(new List<TechTrekApiService.ApiResponse>{ response });
        Test.stopTest();

        Contact updated = [SELECT Id, Title, Department, Email, MailingCity FROM Contact WHERE CNP__c = '1980512123456'];
        Assert.areEqual('Sales Manager', updated.Title, 'Title should be updated');
        Assert.areEqual('Sales', updated.Department, 'Department should be updated');
        Assert.areEqual('andrei.popescu@globaltech.ro', updated.Email, 'Email should be updated');
        Assert.areEqual('Timisoara', updated.MailingCity, 'MailingCity should be updated');
    }

    @isTest
    static void testUpsertContacts_BadJson(){
        TechTrekApiService.ApiResponse response = new TechTrekApiService.ApiResponse();
        response.statusCode = 200;
        response.body = '{"bad": "json"}';

        Test.startTest();
            RecordService.upsertContacts(new List<TechTrekApiService.ApiResponse>{ response });
        Test.stopTest();

        List<Integration_Log__c> logs = [SELECT Id, Error_Type__c FROM Integration_Log__c WHERE Error_Type__c = 'JSON'];
        Assert.isFalse(logs.isEmpty(), 'A JSON error log should have been created');
    }

    @isTest
    static void testUpsertContacts_EmptyList(){
        Test.startTest();
            try {
                RecordService.upsertContacts(new List<TechTrekApiService.ApiResponse>());
                Assert.fail('Should have thrown AuraHandledException');
            }
            catch (AuraHandledException e){
                Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
            }
        Test.stopTest();
    }

    // ── upsertCases ───────────────────────────────────────────────────────────

    @isTest
    static void testUpsertCases_InsertPath(){
        String body = '{'
            + '"serviceTicket": {'
            +   '"ticketInfo": {'
            +     '"referenceNumber": "SR-2026-9999",'
            +     '"title": "New Test Case",'
            +     '"description": "Test description"'
            +   '},'
            +   '"classification": {'
            +     '"category": "Technical",'
            +     '"priorityLevel": "Low"'
            +   '},'
            +   '"statusTracking": {'
            +     '"currentStage": "New",'
            +     '"isEscalated": false,'
            +     '"originChannel": "Web"'
            +   '},'
            +   '"requesterDetails": {'
            +     '"fullName": "Test User",'
            +     '"emailAddress": "test@test.ro"'
            +   '}'
            + '}'
            + '}';

        TechTrekApiService.ApiResponse response = new TechTrekApiService.ApiResponse();
        response.statusCode = 200;
        response.body = body;

        Test.startTest();
            RecordService.upsertCases(new List<TechTrekApiService.ApiResponse>{ response });
        Test.stopTest();

        Case inserted = [SELECT Id, Subject, Priority, Origin, SuppliedName FROM Case WHERE Reference_Number__c = 'SR-2026-9999'];
        Assert.areEqual('New Test Case', inserted.Subject, 'Subject should match');
        Assert.areEqual('Low', inserted.Priority, 'Priority should match');
        Assert.areEqual('Web', inserted.Origin, 'Origin should match');
        Assert.areEqual('Test User', inserted.SuppliedName, 'SuppliedName should match');
    }

    @isTest
    static void testUpsertCases_UpdatePath(){
        // Same Reference_Number__c as the one inserted in @TestSetup → hits UPDATE branch
        String body = '{'
            + '"serviceTicket": {'
            +   '"ticketInfo": {'
            +     '"referenceNumber": "SR-2026-1001",'
            +     '"title": "Billing discrepancy",'
            +     '"description": "Invoice amount mismatch for March billing cycle."'
            +   '},'
            +   '"classification": {'
            +     '"category": "Billing",'
            +     '"priorityLevel": "High"'
            +   '},'
            +   '"statusTracking": {'
            +     '"currentStage": "New",'
            +     '"isEscalated": false,'
            +     '"originChannel": "Email"'
            +   '},'
            +   '"requesterDetails": {'
            +     '"fullName": "Andrei Popescu",'
            +     '"emailAddress": "andrei.popescu@globaltech.ro"'
            +   '}'
            + '}'
            + '}';

        TechTrekApiService.ApiResponse response = new TechTrekApiService.ApiResponse();
        response.statusCode = 200;
        response.body = body;

        Test.startTest();
            RecordService.upsertCases(new List<TechTrekApiService.ApiResponse>{ response });
        Test.stopTest();

        Case updated = [SELECT Id, Subject, Category__c, Priority, Origin, SuppliedName FROM Case WHERE Reference_Number__c = 'SR-2026-1001'];
        Assert.areEqual('Billing discrepancy', updated.Subject, 'Subject should be updated');
        Assert.areEqual('Billing', updated.Category__c, 'Category should be updated');
        Assert.areEqual('High', updated.Priority, 'Priority should be updated');
        Assert.areEqual('Email', updated.Origin, 'Origin should be updated');
        Assert.areEqual('Andrei Popescu', updated.SuppliedName, 'SuppliedName should be updated');
    }

    @isTest
    static void testUpsertCases_BadJson(){
        TechTrekApiService.ApiResponse response = new TechTrekApiService.ApiResponse();
        response.statusCode = 200;
        response.body = '{"bad": "json"}';

        Test.startTest();
            RecordService.upsertCases(new List<TechTrekApiService.ApiResponse>{ response });
        Test.stopTest();

        List<Integration_Log__c> logs = [SELECT Id, Error_Type__c FROM Integration_Log__c WHERE Error_Type__c = 'JSON'];
        Assert.isFalse(logs.isEmpty(), 'A JSON error log should have been created');
    }

    @isTest
    static void testUpsertCases_EmptyList(){
        Test.startTest();
            try {
                RecordService.upsertCases(new List<TechTrekApiService.ApiResponse>());
                Assert.fail('Should have thrown AuraHandledException');
            }
            catch (AuraHandledException e){
                Assert.isNotNull(e.getMessage(), 'Exception message should not be null');
            }
        Test.stopTest();
    }

    @isTest
    static void testUpsertContacts_UpdatePath_FieldsActuallyChange(){
        // Insert contact with OLD values so the != checks are true and assignment lines are hit
        Contact existingCon = new Contact();
        existingCon.FirstName = 'OldFirst';
        existingCon.LastName = 'OldLast';
        existingCon.CNP__c = '2000101111111';
        insert existingCon;

        String body = '{'
            + '"personProfile": {'
            +   '"identity": {'
            +     '"givenName": "NewFirst",'
            +     '"familyName": "NewLast",'
            +     '"personalIdentifier": "2000101111111"'
            +   '},'
            +   '"professionalDetails": {'
            +     '"jobTitle": "Manager",'
            +     '"division": "Sales"'
            +   '},'
            +   '"communication": {'
            +     '"emails": [{'
            +       '"emailAddress": "new@test.ro",'
            +       '"type": "Work",'
            +       '"isPrimary": true'
            +     '}],'
            +     '"phones": [{'
            +       '"phoneNumber": "+40 722 999 999",'
            +       '"type": "Mobile"'
            +     '}]'
            +   '},'
            +   '"residence": {'
            +     '"cityName": "Brasov",'
            +     '"countryName": "Romania"'
            +   '}'
            + '}'
            + '}';

        TechTrekApiService.ApiResponse response = new TechTrekApiService.ApiResponse();
        response.statusCode = 200;
        response.body = body;

        Test.startTest();
            RecordService.upsertContacts(new List<TechTrekApiService.ApiResponse>{ response });
        Test.stopTest();

        Contact updated = [SELECT Id, FirstName, LastName FROM Contact WHERE CNP__c = '2000101111111'];
        Assert.areEqual('NewFirst', updated.FirstName, 'FirstName should have been updated');
        Assert.areEqual('NewLast', updated.LastName, 'LastName should have been updated');
    }

    @isTest
    static void testUpsertContacts_DmlError(){
        // Missing familyName → LastName = null → insert fails → SaveResult error logged
        String body = '{'
            + '"personProfile": {'
            +   '"identity": {'
            +     '"givenName": "NoLast",'
            +     '"familyName": null,'
            +     '"personalIdentifier": "3000101999999"'
            +   '},'
            +   '"professionalDetails": {'
            +     '"jobTitle": "Tester",'
            +     '"division": "QA"'
            +   '},'
            +   '"communication": {'
            +     '"emails": [{'
            +       '"emailAddress": "nolast@test.ro",'
            +       '"type": "Work",'
            +       '"isPrimary": true'
            +     '}],'
            +     '"phones": [{'
            +       '"phoneNumber": "+40 700 000 000",'
            +       '"type": "Mobile"'
            +     '}]'
            +   '},'
            +   '"residence": {'
            +     '"cityName": "Iasi",'
            +     '"countryName": "Romania"'
            +   '}'
            + '}'
            + '}';

        TechTrekApiService.ApiResponse response = new TechTrekApiService.ApiResponse();
        response.statusCode = 200;
        response.body = body;

        Test.startTest();
            RecordService.upsertContacts(new List<TechTrekApiService.ApiResponse>{ response });
        Test.stopTest();

        List<Integration_Log__c> logs = [SELECT Id, Error_Type__c FROM Integration_Log__c WHERE Error_Type__c = 'DML'];
        Assert.isFalse(logs.isEmpty(), 'A DML error log should have been created');
    }
}
