// Recompiled after Facture__c protected-PDF fields were created in the target org.
public with sharing class TB2SI_ProtectedInvoicePdfController {
    private static final String CLASS_NAME = 'TB2SI_ProtectedInvoicePdfController';

    @AuraEnabled
    public static StartResult startGeneration(Id factureId) {
        if (factureId == null) {
            throw new AuraHandledException('Une facture est requise.');
        }

        Facture__c facture = [
            SELECT Id, Name, Protected_PDF_Status__c, Protected_PDF_File_Id__c
            FROM Facture__c
            WHERE Id = :factureId
            WITH USER_MODE
            LIMIT 1
        ];

        if (facture.Protected_PDF_Status__c == 'Queued' || facture.Protected_PDF_Status__c == 'Processing') {
            return new StartResult('InProgress', 'La génération de cette facture est déjà en cours.', null);
        }
        if (facture.Protected_PDF_Status__c == 'Succeeded' && String.isNotBlank(facture.Protected_PDF_File_Id__c)) {
            return new StartResult('Succeeded', 'Le PDF protégé existe déjà. Aucune nouvelle génération n’a été lancée.', facture.Protected_PDF_File_Id__c);
        }

        // The row lock makes two clicks/racing requests converge on one generation.
        Facture__c lockedFacture = [
            SELECT Id, Name, Protected_PDF_Status__c, Protected_PDF_File_Id__c
            FROM Facture__c
            WHERE Id = :factureId
            FOR UPDATE
        ];
        if (lockedFacture.Protected_PDF_Status__c == 'Queued' || lockedFacture.Protected_PDF_Status__c == 'Processing') {
            return new StartResult('InProgress', 'La génération de cette facture est déjà en cours.', null);
        }
        if (lockedFacture.Protected_PDF_Status__c == 'Succeeded' && String.isNotBlank(lockedFacture.Protected_PDF_File_Id__c)) {
            return new StartResult('Succeeded', 'Le PDF protégé existe déjà. Aucune nouvelle génération n’a été lancée.', lockedFacture.Protected_PDF_File_Id__c);
        }

        lockedFacture.Protected_PDF_Status__c = 'Processing';
        lockedFacture.Protected_PDF_Error__c = null;
        lockedFacture.Protected_PDF_File_Id__c = null;
        lockedFacture.Protected_PDF_Generated_At__c = null;
        Database.update(lockedFacture, AccessLevel.USER_MODE);
        System.enqueueJob(new TB2SI_ProtectedInvoicePdfQueueable(factureId, false));

        return new StartResult('Processing', 'La génération du PDF protégé a été planifiée.', null);
    }

    public class StartResult {
        @AuraEnabled public String status;
        @AuraEnabled public String message;
        @AuraEnabled public String fileId;

        public StartResult(String status, String message, String fileId) {
            this.status = status;
            this.message = message;
            this.fileId = fileId;
        }
    }
}
