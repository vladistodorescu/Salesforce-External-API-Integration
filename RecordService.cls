public class RecordService {

    public static void upsertAccounts(List<TechTrekApiService.ApiResponse> apiResponses){
        if (apiResponses.isEmpty()){
            throw new AuraHandledException('The API Responses list cannot be empty!');
        }

        List<Account> accountsToUpdate = new List<Account>();
        List<Account> accountsToInsert = new List<Account>();
        List<Integration_Log__c> logsToInsert = new List<Integration_Log__c>();

        // Step 1 — deserialize all responses into wrappers and collect names
        List<AccountWrapper> wrappers = new List<AccountWrapper>();
        Set<String> existingAccountsNames = new Set<String>();

        for (TechTrekApiService.ApiResponse response : apiResponses){
            try {
                AccountWrapper wrapper = (AccountWrapper) JSON.deserialize(response.body, AccountWrapper.class);
                wrappers.add(wrapper);
                existingAccountsNames.add(wrapper.organization.identity.registeredName);
            }
            catch (Exception e){
                System.debug('Account deserialization failed: ' + e.getMessage());
                Integration_Log__c log = new Integration_Log__c();
                log.Endpoint__c = '/accountEndpoint';
                log.Payload__c = response.body;
                log.Status_Code__c = response.statusCode;
                log.Execution_Time__c = Datetime.now();
                log.Error_Message__c = e.getMessage();
                log.Error_Type__c = 'JSON';
                logsToInsert.add(log);
            }
        }

        if (existingAccountsNames.isEmpty()){
            if (!logsToInsert.isEmpty()) insert logsToInsert;
            return;
        }

        // Step 2 — one single query for all names at once
        Map<String, Account> existingAccountsMap = new Map<String, Account>();

        for (Account acc : [SELECT Id, Name, Sic, Industry, Market_Segment__c, AnnualRevenue,
                                   Fiscal_Currency__c, Fiscal_Year__c, NumberOfEmployees,
                                   Departments__c, Phone, Website, BillingStreet, BillingCity,
                                   BillingPostalCode, BillingCountry
                            FROM Account
                            WHERE Name IN :existingAccountsNames]){
            existingAccountsMap.put(acc.Name, acc);
        }

        // Step 3 — loop wrappers, match in memory, no SOQL
        for (AccountWrapper wrapper : wrappers){
            try {
                String accName = wrapper.organization?.identity?.registeredName;
                String taxId = wrapper.organization?.identity?.taxIdentifier;
                String sector = wrapper.organization?.classification?.sector;
                String marketSegment = wrapper.organization?.classification?.marketSegment;
                Decimal annualTurnover = wrapper.organization?.financialOverview?.annualTurnover;
                String fiscalCurrency = wrapper.organization?.financialOverview?.fiscalCurrency;
                Integer fiscalYear = wrapper.organization?.financialOverview?.fiscalYear;
                Integer employeeCount = wrapper.organization?.workforce?.employeeCount;
                String primaryPhone = wrapper.organization?.communicationChannels?.primaryPhone;
                String website = wrapper.organization?.communicationChannels?.website;
                String street = wrapper.organization?.locations?.headOffice?.streetLine;
                String city = wrapper.organization?.locations?.headOffice?.cityName;
                String postalCode = wrapper.organization?.locations?.headOffice?.postalCode;
                String country = wrapper.organization?.locations?.headOffice?.countryName;

                List<String> depts = wrapper.organization?.workforce?.departments;
                String deptsString = (depts != null && !depts.isEmpty()) ? String.join(depts, ', ') : '';

                if (existingAccountsMap.containsKey(accName)){
                    Account matchedAcc = existingAccountsMap.get(accName);

                    if (matchedAcc.Sic != taxId){
                        matchedAcc.Sic = taxId;
                    }
                    if (matchedAcc.Industry != sector){
                        matchedAcc.Industry = sector;
                    }
                    if (matchedAcc.Market_Segment__c != marketSegment){
                        matchedAcc.Market_Segment__c = marketSegment;
                    }
                    if (matchedAcc.AnnualRevenue != annualTurnover){
                        matchedAcc.AnnualRevenue = annualTurnover;
                    }
                    if (matchedAcc.Fiscal_Currency__c != fiscalCurrency){
                        matchedAcc.Fiscal_Currency__c = fiscalCurrency;
                    }
                    if (matchedAcc.Fiscal_Year__c != fiscalYear){
                        matchedAcc.Fiscal_Year__c = fiscalYear;
                    }
                    if (matchedAcc.NumberOfEmployees != employeeCount){
                        matchedAcc.NumberOfEmployees = employeeCount;
                    }
                    if (matchedAcc.Departments__c != deptsString){
                        matchedAcc.Departments__c = deptsString;
                    }
                    if (matchedAcc.Phone != primaryPhone){
                        matchedAcc.Phone = primaryPhone;
                    }
                    if (matchedAcc.Website != website){
                        matchedAcc.Website = website;
                    }
                    if (matchedAcc.BillingStreet != street){
                        matchedAcc.BillingStreet = street;
                    }
                    if (matchedAcc.BillingCity != city){
                        matchedAcc.BillingCity = city;
                    }
                    if (matchedAcc.BillingPostalCode != postalCode){
                        matchedAcc.BillingPostalCode = postalCode;
                    }
                    if (matchedAcc.BillingCountry != country){
                        matchedAcc.BillingCountry = country;
                    }

                    accountsToUpdate.add(matchedAcc);
                }
                else {
                    Account newAcc = new Account();
                    newAcc.Name = accName;
                    newAcc.Sic = taxId;
                    newAcc.Industry = sector;
                    newAcc.Market_Segment__c = marketSegment;
                    newAcc.AnnualRevenue = annualTurnover;
                    newAcc.Fiscal_Currency__c = fiscalCurrency;
                    newAcc.Fiscal_Year__c = fiscalYear;
                    newAcc.NumberOfEmployees = employeeCount;
                    newAcc.Departments__c = deptsString;
                    newAcc.Phone = primaryPhone;
                    newAcc.Website = website;
                    newAcc.BillingStreet = street;
                    newAcc.BillingCity = city;
                    newAcc.BillingPostalCode = postalCode;
                    newAcc.BillingCountry = country;
                    accountsToInsert.add(newAcc);
                }
            }
            catch (Exception e){
                System.debug('Account mapping error: ' + e.getMessage());
                Integration_Log__c log = new Integration_Log__c();
                log.Endpoint__c = '/accountEndpoint';
                log.Execution_Time__c = Datetime.now();
                log.Error_Message__c = e.getMessage();
                log.Error_Type__c = 'APEX';
                logsToInsert.add(log);
            }
        }

        // Step 4 — bulk DML with partial save + SaveResult logging
        if (!accountsToUpdate.isEmpty()){
            List<Database.SaveResult> results = Database.update(accountsToUpdate, false);
            for (Integer i = 0; i < results.size(); i++){
                if (!results[i].isSuccess()){
                    Database.Error err = results[i].getErrors()[0];
                    Integration_Log__c log = new Integration_Log__c();
                    log.Endpoint__c = '/accountEndpoint';
                    log.Payload__c = JSON.serialize(accountsToUpdate[i]);
                    log.Error_Message__c = err.getMessage();
                    log.Error_Type__c = 'DML';
                    log.Execution_Time__c = Datetime.now();
                    logsToInsert.add(log);
                }
            }
        }

        if (!accountsToInsert.isEmpty()){
            List<Database.SaveResult> results = Database.insert(accountsToInsert, false);
            for (Integer i = 0; i < results.size(); i++){
                if (!results[i].isSuccess()){
                    Database.Error err = results[i].getErrors()[0];
                    Integration_Log__c log = new Integration_Log__c();
                    log.Endpoint__c = '/accountEndpoint';
                    log.Payload__c = JSON.serialize(accountsToInsert[i]);
                    log.Error_Message__c = err.getMessage();
                    log.Error_Type__c = 'DML';
                    log.Execution_Time__c = Datetime.now();
                    logsToInsert.add(log);
                }
            }
        }

        if (!logsToInsert.isEmpty()) insert logsToInsert;
    }

    public static void upsertContacts(List<TechTrekApiService.ApiResponse> apiResponses){
        if (apiResponses.isEmpty()){
            throw new AuraHandledException('The API Responses list cannot be empty!');
        }

        List<Contact> contactsToUpdate = new List<Contact>();
        List<Contact> contactsToInsert = new List<Contact>();
        List<Integration_Log__c> logsToInsert = new List<Integration_Log__c>();

        // Step 1 — deserialize all responses into wrappers and collect CNPs
        List<ContactWrapper> wrappers = new List<ContactWrapper>();
        Set<String> contactCNPs = new Set<String>();

        for (TechTrekApiService.ApiResponse response : apiResponses){
            try {
                ContactWrapper wrapper = (ContactWrapper) JSON.deserialize(response.body, ContactWrapper.class);
                wrappers.add(wrapper);
                contactCNPs.add(wrapper.personProfile.identity.personalIdentifier);
            }
            catch (Exception e){
                System.debug('Contact deserialization failed: ' + e.getMessage());
                Integration_Log__c log = new Integration_Log__c();
                log.Endpoint__c = '/contactEndpoint';
                log.Payload__c = response.body;
                log.Status_Code__c = response.statusCode;
                log.Execution_Time__c = Datetime.now();
                log.Error_Message__c = e.getMessage();
                log.Error_Type__c = 'JSON';
                logsToInsert.add(log);
            }
        }

        if (contactCNPs.isEmpty()){
            if (!logsToInsert.isEmpty()) insert logsToInsert;
            return;
        }

        // Step 2 — one single query for all CNPs at once
        Map<String, Contact> CNPToContactsMap = new Map<String, Contact>();

        for (Contact c : [SELECT Id, FirstName, LastName, CNP__c,
                                 Email, Title, Department, Related_Emails__c,
                                 Related_Phones__c, MailingCity, MailingCountry
                          FROM Contact
                          WHERE CNP__c IN :contactCNPs]){
            CNPToContactsMap.put(c.CNP__c, c);
        }

        // Step 3 — loop wrappers, match in memory, no SOQL
        for (ContactWrapper wrapper : wrappers){
            try {
                String primaryEmail = '';
                List<String> emailAddresses = new List<String>();
                List<String> phoneNumbers = new List<String>();

                for (ContactWrapper.Email emailStruct : wrapper.personProfile.communication.emails){
                    if (emailStruct.isPrimary == true){
                        primaryEmail = emailStruct.emailAddress;
                    }
                    emailAddresses.add(emailStruct.emailAddress);
                }
                for (ContactWrapper.Phone phoneStruct : wrapper.personProfile.communication.phones){
                    phoneNumbers.add(phoneStruct.phoneNumber);
                }

                String expectedEmailsString = String.join(emailAddresses, ', ');
                String expectedPhonesString = String.join(phoneNumbers, ', ');

                Contact matchedContact = CNPToContactsMap.get(wrapper.personProfile.identity.personalIdentifier);

                if (matchedContact != null){
                    if (matchedContact.FirstName != wrapper.personProfile.identity.givenName){
                        matchedContact.FirstName = wrapper.personProfile.identity.givenName;
                    }
                    if (matchedContact.LastName != wrapper.personProfile.identity.familyName){
                        matchedContact.LastName = wrapper.personProfile.identity.familyName;
                    }
                    if (matchedContact.Title != wrapper.personProfile.professionalDetails.jobTitle){
                        matchedContact.Title = wrapper.personProfile.professionalDetails.jobTitle;
                    }
                    if (matchedContact.Department != wrapper.personProfile.professionalDetails.division){
                        matchedContact.Department = wrapper.personProfile.professionalDetails.division;
                    }
                    if (matchedContact.Related_Emails__c != expectedEmailsString){
                        matchedContact.Related_Emails__c = expectedEmailsString;
                    }
                    if (matchedContact.Related_Phones__c != expectedPhonesString){
                        matchedContact.Related_Phones__c = expectedPhonesString;
                    }
                    if (matchedContact.MailingCity != wrapper.personProfile.residence.cityName){
                        matchedContact.MailingCity = wrapper.personProfile.residence.cityName;
                    }
                    if (matchedContact.MailingCountry != wrapper.personProfile.residence.countryName){
                        matchedContact.MailingCountry = wrapper.personProfile.residence.countryName;
                    }
                    if (matchedContact.Email != primaryEmail){
                        matchedContact.Email = primaryEmail;
                    }

                    contactsToUpdate.add(matchedContact);
                }
                else {
                    Contact newCon = new Contact();
                    newCon.FirstName = wrapper.personProfile.identity.givenName;
                    newCon.LastName = wrapper.personProfile.identity.familyName;
                    newCon.CNP__c = wrapper.personProfile.identity.personalIdentifier;
                    newCon.Title = wrapper.personProfile.professionalDetails.jobTitle;
                    newCon.Department = wrapper.personProfile.professionalDetails.division;
                    newCon.Related_Emails__c = expectedEmailsString;
                    newCon.Related_Phones__c = expectedPhonesString;
                    newCon.Email = primaryEmail;
                    newCon.MailingCity = wrapper.personProfile.residence.cityName;
                    newCon.MailingCountry = wrapper.personProfile.residence.countryName;
                    contactsToInsert.add(newCon);
                }
            }
            catch (Exception e){
                System.debug('Contact mapping error: ' + e.getMessage());
                Integration_Log__c log = new Integration_Log__c();
                log.Endpoint__c = '/contactEndpoint';
                log.Execution_Time__c = Datetime.now();
                log.Error_Message__c = e.getMessage();
                log.Error_Type__c = 'APEX';
                logsToInsert.add(log);
            }
        }

        // Step 4 — bulk DML with partial save + SaveResult logging
        if (!contactsToUpdate.isEmpty()){
            List<Database.SaveResult> results = Database.update(contactsToUpdate, false);
            for (Integer i = 0; i < results.size(); i++){
                if (!results[i].isSuccess()){
                    Database.Error err = results[i].getErrors()[0];
                    Integration_Log__c log = new Integration_Log__c();
                    log.Endpoint__c = '/contactEndpoint';
                    log.Payload__c = JSON.serialize(contactsToUpdate[i]);
                    log.Error_Message__c = err.getMessage();
                    log.Error_Type__c = 'DML';
                    log.Execution_Time__c = Datetime.now();
                    logsToInsert.add(log);
                }
            }
        }

        if (!contactsToInsert.isEmpty()){
            List<Database.SaveResult> results = Database.insert(contactsToInsert, false);
            for (Integer i = 0; i < results.size(); i++){
                if (!results[i].isSuccess()){
                    Database.Error err = results[i].getErrors()[0];
                    Integration_Log__c log = new Integration_Log__c();
                    log.Endpoint__c = '/contactEndpoint';
                    log.Payload__c = JSON.serialize(contactsToInsert[i]);
                    log.Error_Message__c = err.getMessage();
                    log.Error_Type__c = 'DML';
                    log.Execution_Time__c = Datetime.now();
                    logsToInsert.add(log);
                }
            }
        }

        if (!logsToInsert.isEmpty()) insert logsToInsert;
    }

    public static void upsertCases(List<TechTrekApiService.ApiResponse> apiResponses){
        if (apiResponses.isEmpty()){
            throw new AuraHandledException('The API Responses list cannot be empty!');
        }

        List<Case> casesToUpdate = new List<Case>();
        List<Case> casesToInsert = new List<Case>();
        List<Integration_Log__c> logsToInsert = new List<Integration_Log__c>();

        // Step 1 — deserialize all responses into wrappers and collect reference numbers
        List<CaseWrapper> caseWrappers = new List<CaseWrapper>();
        Set<String> referenceNumbers = new Set<String>();

        for (TechTrekApiService.ApiResponse response : apiResponses){
            try {
                CaseWrapper wrapper = (CaseWrapper) JSON.deserialize(response.body, CaseWrapper.class);
                caseWrappers.add(wrapper);
                referenceNumbers.add(wrapper.serviceTicket.ticketInfo.referenceNumber);
            }
            catch (Exception e){
                System.debug('Case deserialization failed: ' + e.getMessage());
                Integration_Log__c log = new Integration_Log__c();
                log.Endpoint__c = '/caseEndpoint';
                log.Payload__c = response.body;
                log.Status_Code__c = response.statusCode;
                log.Execution_Time__c = Datetime.now();
                log.Error_Message__c = e.getMessage();
                log.Error_Type__c = 'JSON';
                logsToInsert.add(log);
            }
        }

        if (referenceNumbers.isEmpty()){
            if (!logsToInsert.isEmpty()) insert logsToInsert;
            return;
        }

        // Step 2 — one single query for all reference numbers at once
        Map<String, Case> referenceNrToCaseMap = new Map<String, Case>();

        for (Case c : [SELECT Id, Subject, Description, Reference_Number__c,
                              Category__c, Priority, Status, Origin,
                              SuppliedName, SuppliedEmail
                       FROM Case
                       WHERE Reference_Number__c IN :referenceNumbers]){
            referenceNrToCaseMap.put(c.Reference_Number__c, c);
        }

        // Step 3 — loop wrappers, match in memory, no SOQL
        for (CaseWrapper wrapper : caseWrappers){
            try {
                Case matchedCase = referenceNrToCaseMap.get(wrapper.serviceTicket.ticketInfo.referenceNumber);

                if (matchedCase != null){
                    if (matchedCase.Subject != wrapper.serviceTicket.ticketInfo.title){
                        matchedCase.Subject = wrapper.serviceTicket.ticketInfo.title;
                    }
                    if (matchedCase.Description != wrapper.serviceTicket.ticketInfo.description){
                        matchedCase.Description = wrapper.serviceTicket.ticketInfo.description;
                    }
                    if (matchedCase.Category__c != wrapper.serviceTicket.classification.category){
                        matchedCase.Category__c = wrapper.serviceTicket.classification.category;
                    }
                    if (matchedCase.Priority != wrapper.serviceTicket.classification.priorityLevel){
                        matchedCase.Priority = wrapper.serviceTicket.classification.priorityLevel;
                    }
                    if (matchedCase.Status != wrapper.serviceTicket.statusTracking.currentStage){
                        matchedCase.Status = wrapper.serviceTicket.statusTracking.currentStage;
                    }
                    if (matchedCase.Origin != wrapper.serviceTicket.statusTracking.originChannel){
                        matchedCase.Origin = wrapper.serviceTicket.statusTracking.originChannel;
                    }
                    if (matchedCase.SuppliedName != wrapper.serviceTicket.requesterDetails.fullName){
                        matchedCase.SuppliedName = wrapper.serviceTicket.requesterDetails.fullName;
                    }
                    if (matchedCase.SuppliedEmail != wrapper.serviceTicket.requesterDetails.emailAddress){
                        matchedCase.SuppliedEmail = wrapper.serviceTicket.requesterDetails.emailAddress;
                    }

                    casesToUpdate.add(matchedCase);
                }
                else {
                    Case newCase = new Case();
                    newCase.Reference_Number__c = wrapper.serviceTicket.ticketInfo.referenceNumber;
                    newCase.Subject = wrapper.serviceTicket.ticketInfo.title;
                    newCase.Description = wrapper.serviceTicket.ticketInfo.description;
                    newCase.Category__c = wrapper.serviceTicket.classification.category;
                    newCase.Priority = wrapper.serviceTicket.classification.priorityLevel;
                    newCase.Status = wrapper.serviceTicket.statusTracking.currentStage;
                    newCase.Origin = wrapper.serviceTicket.statusTracking.originChannel;
                    newCase.SuppliedName = wrapper.serviceTicket.requesterDetails.fullName;
                    newCase.SuppliedEmail = wrapper.serviceTicket.requesterDetails.emailAddress;
                    casesToInsert.add(newCase);
                }
            }
            catch (Exception e){
                System.debug('Case mapping error: ' + e.getMessage());
                Integration_Log__c log = new Integration_Log__c();
                log.Endpoint__c = '/caseEndpoint';
                log.Execution_Time__c = Datetime.now();
                log.Error_Message__c = e.getMessage();
                log.Error_Type__c = 'APEX';
                logsToInsert.add(log);
            }
        }

        // Step 4 — bulk DML with partial save + SaveResult logging
        if (!casesToUpdate.isEmpty()){
            List<Database.SaveResult> results = Database.update(casesToUpdate, false);
            for (Integer i = 0; i < results.size(); i++){
                if (!results[i].isSuccess()){
                    Database.Error err = results[i].getErrors()[0];
                    Integration_Log__c log = new Integration_Log__c();
                    log.Endpoint__c = '/caseEndpoint';
                    log.Payload__c = JSON.serialize(casesToUpdate[i]);
                    log.Error_Message__c = err.getMessage();
                    log.Error_Type__c = 'DML';
                    log.Execution_Time__c = Datetime.now();
                    logsToInsert.add(log);
                }
            }
        }

        if (!casesToInsert.isEmpty()){
            List<Database.SaveResult> results = Database.insert(casesToInsert, false);
            for (Integer i = 0; i < results.size(); i++){
                if (!results[i].isSuccess()){
                    Database.Error err = results[i].getErrors()[0];
                    Integration_Log__c log = new Integration_Log__c();
                    log.Endpoint__c = '/caseEndpoint';
                    log.Payload__c = JSON.serialize(casesToInsert[i]);
                    log.Error_Message__c = err.getMessage();
                    log.Error_Type__c = 'DML';
                    log.Execution_Time__c = Datetime.now();
                    logsToInsert.add(log);
                }
            }
        }

        if (!logsToInsert.isEmpty()) insert logsToInsert;
    }
}
