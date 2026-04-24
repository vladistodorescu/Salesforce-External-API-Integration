public class AccountWrapper {
    public Organization organization;

    public class Organization{
        public Identity identity; 
        public Classification classification;
        public FinancialOverview financialOverview; 
        public Workforce workforce;
        public CommChannels communicationChannels; 
        public Locations locations;
    }

    public class Identity{
        public String registeredName;
        public String taxIdentifier;
    }

    public class Classification{    
        public String sector;
        public String marketSegment;
    }

    public class FinancialOverview{
        public Decimal annualTurnover;
        public String fiscalCurrency;
        public Integer fiscalYear;
    }

    public class Workforce{
        public Integer employeeCount;
        public List<String> departments;
    }

    public class CommChannels{
        public String primaryPhone;
        public String website;
    }

    public class Locations {
        public HeadOffice headOffice; 
    }

    public class HeadOffice {
        public String streetLine;
        public String cityName;
        public String postalCode;
        public String countryName;
    }
}
