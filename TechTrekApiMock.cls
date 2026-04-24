@isTest
public class TechTrekApiMock implements HttpCalloutMock{
    private Integer accStatusCode; 
    private Integer conStatusCode;
    private Integer caseStatusCode;

    public TechTrekApiMock(Integer accStatusCode, Integer conStatusCode, Integer caseStatusCode) {
        this.accStatusCode = accStatusCode;
        this.conStatusCode = conStatusCode;
        this.caseStatusCode = caseStatusCode;
    }

    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        String url = request.getEndpoint();

        if (url.contains('/accountEndpoint')){
            response.setStatusCode(accStatusCode);
            if (accStatusCode == 200){
                response.setStatus('OK');
                response.setBody(getAccountStub());
            }
            else{
                response.setStatus('Bad Request');
                response.setBody('{"error": "Missing or invalid type parameter"}');
            }
        }
        if (url.contains('/contactEndpoint')){
            response.setStatusCode(conStatusCode);
            if (conStatusCode == 200){
                response.setStatus('OK');
                response.setBody(getContactStub());   
            }
            else{
                response.setStatus('Bad Request');
                response.setBody('{"error": "Missing or invalid type parameter"}');
            }
        }
        if (url.contains('/caseEndpoint')){
            response.setStatusCode(caseStatusCode);
            if (caseStatusCode == 200){
                response.setStatus('OK');
                response.setBody(getCaseStub());   
            }
            else{
                response.setStatus('Bad Request');
                response.setBody('{"error": "Missing or invalid type parameter"}');
            }
        }

        return response;
    }

    private String getAccountStub() {
        return '{'
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
    }

    private String getContactStub() {
        return '{'
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
    }

    private String getCaseStub() {
        return '{'
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
    }
}
