public with sharing class TechTrekApiService {
    // API response wrapper
    public class ApiResponse{
        public Integer statusCode;
        public String status;
        public String body;
        public Boolean isSuccess{ 
            get {return statusCode == 200;}
        }
    }

    // base url and the endpoint paths
    private static final String BASE_URL     = 'https://350e1661-604c-4300-b78b-4e3002bfeae4.mock.pstmn.io';
    private static final String ENDPOINT_ACCOUNT = '/accountEndpoint';
    private static final String ENDPOINT_CONTACT = '/contactEndpoint';
    private static final String ENDPOINT_CASE    = '/caseEndpoint';

    // execute API request to the external server, return response in wrapper class
    private static ApiResponse execute(String endpoint, Integer typeValue){
        ApiResponse apiResponse = new ApiResponse();

        try{
            String fullURL = BASE_URL + endpoint + '?type=' + typeValue;

            HttpRequest request = new HttpRequest();
            request.setEndpoint(fullURL);
            request.setMethod('GET');
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(10000);

            Http http = new Http();
            HttpResponse response = http.send(request);

            apiResponse.statusCode = response.getStatusCode();
            apiResponse.status = response.getStatus();
            apiResponse.body = response.getBody();
        }
        catch (CalloutException e){
            apiResponse.statusCode = 500;
            apiResponse.status = 'Callout Failed';
            apiResponse.body = 'Error: ' + e.getMessage();
            System.debug('TechTrekApiService ERROR on ' + endpoint + ' — ' + e.getMessage());
        }

        return apiResponse;
    }

    // Helpers for calling specific endpoints already configured
    public static ApiResponse callAccountEndpoint(Integer typeValue){
        return execute(ENDPOINT_ACCOUNT, typeValue);
    }

    public static ApiResponse callContactEndpoint(Integer typeValue){
        return execute(ENDPOINT_CONTACT, typeValue);
    }

    public static ApiResponse callCaseEndpoint(Integer typeValue){
        return execute(ENDPOINT_CASE, typeValue);
    }

}
