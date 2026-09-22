// Recompiled after Facture__c protected-PDF fields were created in the target org.
public with sharing class TB2SI_ProtectedInvoicePdfPageController {
    public Facture__c facture { get; private set; }
    public List<LineView> lines { get; private set; }

    public TB2SI_ProtectedInvoicePdfPageController() {
        String recordId = ApexPages.currentPage().getParameters().get('id');
        if (String.isBlank(recordId)) {
            throw new VisualforceException('L’identifiant de la facture est requis.');
        }

        facture = [
            SELECT Id, Name, Date_facture__c, Date_echeance__c, Client__c, Client__r.Name,
                (SELECT Id, Name, Description__c, Quantite__c, Prix_unitaire_HT__c, TVA__c
                 FROM Lignes_de_facture__r ORDER BY CreatedDate, Id)
            FROM Facture__c
            WHERE Id = :recordId
            WITH USER_MODE
            LIMIT 1
        ];

        lines = new List<LineView>();
        for (Ligne_de_facture__c line : facture.Lignes_de_facture__r) {
            lines.add(new LineView(line));
        }
    }

    public Decimal getTotalHt() {
        Decimal total = 0;
        for (LineView line : lines) total += line.totalHt;
        return total.setScale(2);
    }

    public Decimal getTotalTva() {
        Decimal total = 0;
        for (LineView line : lines) total += line.totalTva;
        return total.setScale(2);
    }

    public Decimal getTotalTtc() {
        return (getTotalHt() + getTotalTva()).setScale(2);
    }

    public class LineView {
        public String description { get; private set; }
        public Decimal quantity { get; private set; }
        public Decimal unitPrice { get; private set; }
        public String tvaLabel { get; private set; }
        public Decimal tvaRate { get; private set; }
        public Decimal totalHt { get; private set; }
        public Decimal totalTva { get; private set; }
        public Decimal totalTtc { get { return (totalHt + totalTva).setScale(2); } }

        public LineView(Ligne_de_facture__c source) {
            description = source.Description__c;
            quantity = source.Quantite__c == null ? 0 : source.Quantite__c;
            unitPrice = source.Prix_unitaire_HT__c == null ? 0 : source.Prix_unitaire_HT__c;
            tvaRate = rateFor(source.TVA__c);
            tvaLabel = source.TVA__c == null ? '0 %' : labelFor(source.TVA__c);
            totalHt = (quantity * unitPrice).setScale(2);
            totalTva = (totalHt * tvaRate / 100).setScale(2);
        }

        private Decimal rateFor(String value) {
            if (value == 'FR_200') return 20;
            if (value == 'FR_100') return 10;
            if (value == 'FR_055') return 5.5;
            if (value == 'FR_021') return 2.1;
            return 0;
        }

        private String labelFor(String value) {
            if (value == 'FR_200') return '20 %';
            if (value == 'FR_100') return '10 %';
            if (value == 'FR_055') return '5,5 %';
            if (value == 'FR_021') return '2,1 %';
            return '0 %';
        }
    }
}
