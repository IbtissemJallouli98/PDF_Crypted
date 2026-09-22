// Recompiled after Facture__c protected-PDF fields were created in the target org.
public with sharing class TB2SI_ProtectedInvoicePdfQueueable implements Queueable, Database.AllowsCallouts {
    @TestVisible private static final Integer MAX_SOURCE_PDF_BYTES = 4500000;
    private final Id factureId;
    private final Boolean markProcessing;

    public TB2SI_ProtectedInvoicePdfQueueable(Id factureId, Boolean markProcessing) {
        this.factureId = factureId;
        this.markProcessing = markProcessing;
    }

    public void execute(QueueableContext context) {
        if (markProcessing) {
            markProcessingAndChain();
        } else {
            generateAndProtect();
        }
    }

    private void markProcessingAndChain() {
        Facture__c facture = [
            SELECT Id, Protected_PDF_Status__c
            FROM Facture__c
            WHERE Id = :factureId
            WITH USER_MODE
            LIMIT 1
        ];
        if (facture.Protected_PDF_Status__c != 'Queued') return;

        facture.Protected_PDF_Status__c = 'Processing';
        Database.update(facture, AccessLevel.USER_MODE);
        System.enqueueJob(new TB2SI_ProtectedInvoicePdfQueueable(factureId, false));
    }

    private void generateAndProtect() {
        try {
            Facture__c facture = [
                SELECT Id, Name, Protected_PDF_Status__c,
                    Client__r.Name,
                    Client__r.Procurement_Main_Contact__c,
                    Client__r.Procurement_Main_Contact__r.Name,
                    Client__r.Procurement_Main_Contact__r.Email,
                    Client__r.Procurement_Main_Contact__r.HasOptedOutOfEmail
                FROM Facture__c
                WHERE Id = :factureId
                WITH USER_MODE
                LIMIT 1
            ];
            if (facture.Protected_PDF_Status__c != 'Processing') return;

            // getContentAsPDF is unavailable in Apex tests; the production path always renders the page.
            Blob sourcePdf = Test.isRunningTest()
                ? Blob.valueOf('%PDF-1.7 test invoice')
                : new PageReference('/apex/TB2SI_ProtectedInvoicePdf?id=' + String.valueOf(factureId)).getContentAsPDF();
            if (sourcePdf == null || sourcePdf.size() == 0 || sourcePdf.size() > MAX_SOURCE_PDF_BYTES) {
                throw new PdfGenerationException('La taille du PDF source est invalide ou dépasse la limite autorisée.');
            }

            String userPassword = EncodingUtil.convertToHex(Crypto.generateAESKey(256));
            String ownerPassword = EncodingUtil.convertToHex(Crypto.generateAESKey(256));
            Blob protectedPdf = TB2SI_ProtectedInvoicePdfClient.encrypt(sourcePdf, userPassword, ownerPassword);
            if (protectedPdf == null || protectedPdf.size() == 0) {
                throw new PdfGenerationException('Le service n’a retourné aucun PDF protégé.');
            }

            ContentVersion version = new ContentVersion(
                Title = facture.Name + '-PDF-protege',
                PathOnClient = facture.Name + '-PDF-protege.pdf',
                VersionData = protectedPdf,
                ContentLocation = 'S',
                IsMajorVersion = true,
                FirstPublishLocationId = facture.Id
            );
            insert version;

            sendPasswordEmail(facture, userPassword);

            ContentVersion savedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id LIMIT 1];
            facture.Protected_PDF_Status__c = 'Succeeded';
            facture.Protected_PDF_File_Id__c = savedVersion.ContentDocumentId;
            facture.Protected_PDF_Error__c = null;
            facture.Protected_PDF_Generated_At__c = System.now();
            Database.update(facture, AccessLevel.USER_MODE);
        } catch (Exception e) {
            markFailed(e);
        }
    }

    private static void sendPasswordEmail(Facture__c facture, String userPassword) {
        Contact mainContact = facture.Client__r == null
            ? null
            : facture.Client__r.Procurement_Main_Contact__r;
        if (mainContact == null || String.isBlank(mainContact.Email)) {
            throw new PdfGenerationException('Le compte de la facture n’a pas de contact principal avec une adresse email.');
        }
        if (mainContact.HasOptedOutOfEmail) {
            throw new PdfGenerationException('Le contact principal du compte refuse les emails.');
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{mainContact.Email});
        email.setSubject('Mot de passe du PDF protégé - ' + facture.Name);
        email.setPlainTextBody(
            'Bonjour,' + '\n\n' +
            'Le PDF protégé de la facture ' + facture.Name + ' est disponible dans Salesforce.' + '\n' +
            'Mot de passe d’ouverture : ' + userPassword + '\n\n' +
            'Ce mot de passe est confidentiel. Ne le partagez pas.'
        );
        email.setSaveAsActivity(false);

        Messaging.SendEmailResult[] results = Messaging.sendEmail(
            new List<Messaging.Email>{email},
            false
        );
        if (results.isEmpty() || !results[0].isSuccess()) {
            throw new PdfGenerationException('L’email contenant le mot de passe n’a pas pu être envoyé.');
        }
    }

    private void markFailed(Exception error) {
        try {
            Facture__c facture = [SELECT Id FROM Facture__c WHERE Id = :factureId WITH USER_MODE LIMIT 1];
            facture.Protected_PDF_Status__c = 'Failed';
            facture.Protected_PDF_Error__c = safeError(error);
            Database.update(facture, AccessLevel.USER_MODE);
        } catch (Exception ignored) {
            // Do not expose or log PDF/password/callout data if the status update itself fails.
        }
    }

    private static String safeError(Exception error) {
        String message = error == null ? 'Erreur inconnue.' : error.getMessage();
        if (String.isBlank(message)) message = 'Erreur inconnue.';
        message = message.replaceAll('(?i)(password|mot de passe|authorization|bearer|token)\\s*[:=]\\s*[^,; ]+', '$1=[redacted]');
        return message.length() > 255 ? message.substring(0, 255) : message;
    }

    private class PdfGenerationException extends Exception {}
}
