public class ContactWrapper {
    public PersonProfile personProfile;

    public class PersonProfile{
        public Identity identity;
        public ProfessionalDetails professionalDetails;
        public Communication communication;
        public Residence residence;
    }

    public class Identity{
        public String givenName;
        public String familyName;
        public String personalIdentifier;
    }

    public class ProfessionalDetails{
        public String jobTitle;
        public String division;
    }

    public class Communication{
        public List<Email> emails;
        public List<Phone> phones;
    }

    public class Email{
        public String emailAddress;
        public String type;
        public Boolean isPrimary;
    }   

    public class Phone{
        public String phoneNumber;
        public String type;
    }
    
    public class Residence{
        public String cityName;
        public String countryName;
    }
}
