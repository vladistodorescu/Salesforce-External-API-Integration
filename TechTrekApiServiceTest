@isTest
private class TechTrekApiServiceTest {
    @IsTest
    static void testGetAccountSuccess() {

        Test.setMock(HttpCalloutMock.class, new TechTrekApiMock(200, null, null)); 

        Test.startTest(); 
            TechTrekApiService.ApiResponse res = TechTrekApiService.callAccountEndpoint(0); 
        Test.stopTest();

        Assert.areEqual(200, res.statusCode, 'Status code should be 200');
        Assert.isTrue(res.isSuccess, 'isSuccess should be true for 200');
        Assert.isNotNull(res.body, 'Body should not be null');

        AccountWrapper wrapper = (AccountWrapper) JSON.deserialize(res.body, AccountWrapper.class); 

        // Test Identity fields
        Assert.areEqual('Global Tech Industries', wrapper.organization.identity.registeredName, 'Company Name is not as expected!');
        Assert.areEqual('RO12345678', wrapper.organization.identity.taxIdentifier, 'Tax Identifier is not as expected!');

        // Test Classification fields
        Assert.areEqual('Manufacturing', wrapper.organization.classification.sector, 'Sector is not as expected!');
        Assert.areEqual('B2B', wrapper.organization.classification.marketSegment, 'Market Segment is not as expected!');

        // Test Financial Overview fields
        Assert.areEqual(3200000, wrapper.organization.financialOverview.annualTurnover, 'Turnover is not as expected!');
        Assert.areEqual('EUR', wrapper.organization.financialOverview.fiscalCurrency, 'Fiscal Currency is not as expected!');
        Assert.areEqual(2025, wrapper.organization.financialOverview.fiscalYear, 'Fiscal Year is not as expected!');

        // Test Workforce fields
        Assert.areEqual(240, wrapper.organization.workforce.employeeCount, 'Employee Count is not as expected!');
        Assert.areEqual('Production', wrapper.organization.workforce.departments[0], 'First Department is not as expected!');
        Assert.areEqual('Logistics', wrapper.organization.workforce.departments[1], 'Second Department is not as expected!');
        Assert.areEqual('Sales', wrapper.organization.workforce.departments[2], 'Third Department is not as expected!');

        // Test Communication Channels fields
        Assert.areEqual('+40 21 555 7788', wrapper.organization.communicationChannels.primaryPhone, 'Primary Phone is not as expected!');
        Assert.areEqual('https://globaltech.ro', wrapper.organization.communicationChannels.website, 'Website is not as expected!');

        // Test Locations fields
        Assert.areEqual('Timisoara', wrapper.organization.locations.headOffice.cityName, 'Head Office City is not as expected!');
        Assert.areEqual('Str. Fabricii 12', wrapper.organization.locations.headOffice.streetLine, 'Head Office Address Street is not as expected!');
        Assert.areEqual('300123', wrapper.organization.locations.headOffice.postalCode, 'Head Office Postal Code is not as expected!');
        Assert.areEqual('Romania', wrapper.organization.locations.headOffice.countryName, 'Head Office Country is not as expected!');
    }
}
