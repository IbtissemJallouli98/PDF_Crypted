// Recompiled after Facture__c protected-PDF fields were created in the target org.
public with sharing class TB2SI_ProtectedInvoicePdfClient {
    @TestVisible private static final String ENDPOINT = 'callout:TB2SI_PdfEncryption/v1/pdf/encrypt';
    @TestVisible private static final Integer TIMEOUT_MS = 20000;

    public class EncryptionException extends Exception {}

    public static Blob encrypt(Blob pdf, String userPassword, String ownerPassword) {
        if (pdf == null || pdf.size() == 0) throw new EncryptionException('Le PDF source est vide.');
        if (String.isBlank(userPassword) || String.isBlank(ownerPassword) || userPassword == ownerPassword) {
            throw new EncryptionException('Les mots de passe PDF sont invalides.');
        }

        Map<String, Object> payload = new Map<String, Object>{
            'pdfBase64' => EncodingUtil.base64Encode(pdf),
            'userPassword' => userPassword,
            'ownerPassword' => ownerPassword
        };

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(ENDPOINT);
        request.setTimeout(TIMEOUT_MS);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(payload));

        HttpResponse response = new Http().send(request);
        if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
            throw new EncryptionException('Le service de chiffrement a refusé le PDF (HTTP ' + response.getStatusCode() + ').');
        }

        Map<String, Object> body;
        try {
            body = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        } catch (Exception e) {
            throw new EncryptionException('La réponse du service de chiffrement est invalide.');
        }
        String encryptedBase64 = (String) body.get('pdfBase64');
        if (String.isBlank(encryptedBase64)) {
            throw new EncryptionException('La réponse du service ne contient pas de PDF protégé.');
        }
        try {
            return EncodingUtil.base64Decode(encryptedBase64);
        } catch (Exception e) {
            throw new EncryptionException('Le PDF protégé retourné est invalide.');
        }
    }
}
