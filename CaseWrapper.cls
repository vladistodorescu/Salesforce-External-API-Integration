   public class CaseWrapper {
    public ServiceTicket serviceTicket;

    public class ServiceTicket{
        public TicketInfo ticketInfo;
        public Classification classification;
        public StatusTracking statusTracking;
        public RequesterDetails requesterDetails;
    }

    public class TicketInfo{
        public String referenceNumber;
        public String title;
        public String description;
    }

    public class Classification{
        public String category;
        public String priorityLevel;
    }

    public class StatusTracking{
        public String currentStage;
        public Boolean isEscalated;
        public String originChannel;
    }

    public class RequesterDetails{
        public String fullName;
        public String emailAddress;
    }
}
