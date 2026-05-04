public class TechTrekBatch implements Database.Batchable<Integer>, Database.AllowsCallouts, Schedulable {
    // Database.Batchable<Integer> for making it a batch class, and recieves intger as parameter (type=0...6)
    // Database.AllowCallouts for allowing Batch classes to make HTTP Callout (not allowed by default)
    // Schedulable, for allowing the class to be scheduled
    private static final Integer MIN_TYPE = 0;
    private static final Integer MAX_TYPE = 6;

    // ── Schedulable ────────────────────────────────────────────────────────────
    // System.schedule('TechTrekBatch Daily', '0 0 2 * * ?', new TechTrekBatch());
    public void execute(SchedulableContext sc){
        Database.executeBatch(new TechTrekBatch(), 1);
    }

    // ── Batchable ──────────────────────────────────────────────────────────────
    public List<Integer> start(Database.BatchableContext bc){
        List<Integer> typeValues = new List<Integer>();

        if (Test.isRunningTest()){
            typeValues.add(0); // only one execution in test context
            return typeValues;
        }

        for (Integer i = MIN_TYPE; i <= MAX_TYPE; i++){
            typeValues.add(i);
        }
        return typeValues;
    }

    public void execute(Database.BatchableContext bc, List<Integer> scope){
        List<TechTrekApiService.ApiResponse> accountResponses = new List<TechTrekApiService.ApiResponse>();
        List<TechTrekApiService.ApiResponse> contactResponses = new List<TechTrekApiService.ApiResponse>();
        List<TechTrekApiService.ApiResponse> caseResponses = new List<TechTrekApiService.ApiResponse>();
        List<Integration_Log__c> logsToInsert = new List<Integration_Log__c>();

        // Step 1 — call all three endpoints for each type in scope
        for (Integer typeValue : scope){
            String typeStr = String.valueOf(typeValue);

            // Account callout
            try {
                TechTrekApiService.ApiResponse resp = TechTrekApiService.callAccountEndpoint(typeValue);
                if (resp.isSuccess){
                    accountResponses.add(resp);
                }
                else {
                    Integration_Log__c log = new Integration_Log__c();
                    log.Endpoint__c = '/accountEndpoint';
                    log.Request_Type__c = typeStr;
                    log.Status_Code__c = resp.statusCode;
                    log.Payload__c = resp.body;
                    log.Error_Message__c = 'Non-200 response: ' + resp.status;
                    log.Error_Type__c = 'HTTP';
                    log.Execution_Time__c = Datetime.now();
                    logsToInsert.add(log);
                }
            }
            catch (Exception e){
                Integration_Log__c log = new Integration_Log__c();
                log.Endpoint__c = '/accountEndpoint';
                log.Request_Type__c = typeStr;
                log.Error_Message__c = e.getMessage();
                log.Error_Type__c = 'APEX';
                log.Execution_Time__c = Datetime.now();
                logsToInsert.add(log);
            }

            // Contact callout
            try {
                TechTrekApiService.ApiResponse resp = TechTrekApiService.callContactEndpoint(typeValue);
                if (resp.isSuccess){
                    contactResponses.add(resp);
                }
                else {
                    Integration_Log__c log = new Integration_Log__c();
                    log.Endpoint__c = '/contactEndpoint';
                    log.Request_Type__c = typeStr;
                    log.Status_Code__c = resp.statusCode;
                    log.Payload__c = resp.body;
                    log.Error_Message__c = 'Non-200 response: ' + resp.status;
                    log.Error_Type__c = 'HTTP';
                    log.Execution_Time__c = Datetime.now();
                    logsToInsert.add(log);
                }
            }
            catch (Exception e){
                Integration_Log__c log = new Integration_Log__c();
                log.Endpoint__c = '/contactEndpoint';
                log.Request_Type__c = typeStr;
                log.Error_Message__c = e.getMessage();
                log.Error_Type__c = 'APEX';
                log.Execution_Time__c = Datetime.now();
                logsToInsert.add(log);
            }

            // Case callout
            try {
                TechTrekApiService.ApiResponse resp = TechTrekApiService.callCaseEndpoint(typeValue);
                if (resp.isSuccess){
                    caseResponses.add(resp);
                }
                else {
                    Integration_Log__c log = new Integration_Log__c();
                    log.Endpoint__c = '/caseEndpoint';
                    log.Request_Type__c = typeStr;
                    log.Status_Code__c = resp.statusCode;
                    log.Payload__c = resp.body;
                    log.Error_Message__c = 'Non-200 response: ' + resp.status;
                    log.Error_Type__c = 'HTTP';
                    log.Execution_Time__c = Datetime.now();
                    logsToInsert.add(log);
                }
            }
            catch (Exception e){
                Integration_Log__c log = new Integration_Log__c();
                log.Endpoint__c = '/caseEndpoint';
                log.Request_Type__c = typeStr;
                log.Error_Message__c = e.getMessage();
                log.Error_Type__c = 'APEX';
                log.Execution_Time__c = Datetime.now();
                logsToInsert.add(log);
            }
        }

        // Step 2 — pass successful responses to RecordService
        if (!accountResponses.isEmpty()){
            try {
                RecordService.upsertAccounts(accountResponses);
            }
            catch (Exception e){
                Integration_Log__c log = new Integration_Log__c();
                log.Endpoint__c = '/accountEndpoint';
                log.Error_Message__c = e.getMessage();
                log.Error_Type__c = 'DML';
                log.Execution_Time__c = Datetime.now();
                logsToInsert.add(log);
            }
        }

        if (!contactResponses.isEmpty()){
            try {
                RecordService.upsertContacts(contactResponses);
            }
            catch (Exception e){
                Integration_Log__c log = new Integration_Log__c();
                log.Endpoint__c = '/contactEndpoint';
                log.Error_Message__c = e.getMessage();
                log.Error_Type__c = 'DML';
                log.Execution_Time__c = Datetime.now();
                logsToInsert.add(log);
            }
        }

        if (!caseResponses.isEmpty()){
            try {
                RecordService.upsertCases(caseResponses);
            }
            catch (Exception e){
                Integration_Log__c log = new Integration_Log__c();
                log.Endpoint__c = '/caseEndpoint';
                log.Error_Message__c = e.getMessage();
                log.Error_Type__c = 'DML';
                log.Execution_Time__c = Datetime.now();
                logsToInsert.add(log);
            }
        }

        // Step 3 — flush all batch-level logs in one DML
        if (!logsToInsert.isEmpty()){
            insert logsToInsert;
        }
    }

    public void finish(Database.BatchableContext bc){
        System.debug('TechTrekBatch finished successfully.');
    }
}
