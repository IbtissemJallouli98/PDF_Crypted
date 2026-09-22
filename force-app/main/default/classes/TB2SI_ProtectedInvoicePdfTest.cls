@IsTest
private class TB2SI_ProtectedInvoicePdfTest {
    @TestSetup
    static void setupData() {
        PermissionSet permissions = [SELECT Id FROM PermissionSet WHERE Name = 'TB2SI_ProtectedInvoicePdf' LIMIT 1];
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissions.Id);
        }

        Account client = new Account(Name = 'Client facture test');
        insert client;
        Facture__c facture = new Facture__c(
            Client__c = client.Id,
            Date_facture__c = Date.newInstance(2026, 9, 21),
            Date_echeance__c = Date.newInstance(2026, 10, 21),
            Protected_PDF_Status__c = 'NotStarted'
        );
        Database.insert(facture, AccessLevel.SYSTEM_MODE);
        Database.insert(new List<Ligne_de_facture__c>{
            new Ligne_de_facture__c(Facture__c = facture.Id, Description__c = 'Conseil', Quantite__c = 2, Prix_unitaire_HT__c = 100, TVA__c = 'FR_200'),
            new Ligne_de_facture__c(Facture__c = facture.Id, Description__c = 'Support', Quantite__c = 1, Prix_unitaire_HT__c = 50, TVA__c = 'FR_100')
        }, AccessLevel.SYSTEM_MODE);
    }

    @IsTest
    static void generatesProtectedFileAndUsesInvoiceData() {
        Facture__c facture = [SELECT Id FROM Facture__c LIMIT 1];
        User authorizedUser = createAuthorizedUser();
        Test.setMock(HttpCalloutMock.class, new EncryptionMock(false));

        TB2SI_ProtectedInvoicePdfController.StartResult result;
        System.runAs(authorizedUser) {
            Test.startTest();
            result = TB2SI_ProtectedInvoicePdfController.startGeneration(facture.Id);
            Test.stopTest();
        }

        System.assertEquals('Processing', result.status);
        Facture__c saved;
        List<ContentDocumentLink> links;
        System.runAs(authorizedUser) {
            saved = [
                SELECT Protected_PDF_Status__c, Protected_PDF_File_Id__c, Protected_PDF_Error__c,
                    Protected_PDF_Generated_At__c
                FROM Facture__c WHERE Id = :facture.Id
            ];
            links = [
                SELECT ContentDocumentId, LinkedEntityId, ContentDocument.LatestPublishedVersion.PathOnClient
                FROM ContentDocumentLink WHERE LinkedEntityId = :facture.Id
            ];
        }
        System.assertEquals('Succeeded', saved.Protected_PDF_Status__c);
        System.assertNotEquals(null, saved.Protected_PDF_File_Id__c);
        System.assertEquals(null, saved.Protected_PDF_Error__c);
        System.assertNotEquals(null, saved.Protected_PDF_Generated_At__c);

        System.assertEquals(1, links.size());
        System.assertEquals(facture.Id, links[0].LinkedEntityId);
        System.assert(links[0].ContentDocument.LatestPublishedVersion.PathOnClient.endsWith('.pdf'));
    }

    @IsTest
    static void pageControllerMapsInvoiceAndLines() {
        Facture__c facture = [SELECT Id FROM Facture__c LIMIT 1];
        User authorizedUser = createAuthorizedUser();
        System.runAs(authorizedUser) {
            Test.setCurrentPage(new PageReference('/apex/TB2SI_ProtectedInvoicePdf'));
            ApexPages.currentPage().getParameters().put('id', facture.Id);

            TB2SI_ProtectedInvoicePdfPageController controller = new TB2SI_ProtectedInvoicePdfPageController();

            System.assertEquals(facture.Id, controller.facture.Id);
            System.assertEquals('Client facture test', controller.facture.Client__r.Name);
            System.assertEquals(2, controller.lines.size());
            System.assertEquals(250, controller.getTotalHt());
            System.assertEquals(45, controller.getTotalTva());
            System.assertEquals(295, controller.getTotalTtc());
        }
    }

    @IsTest
    static void encryptionFailureMarksFailureAndDoesNotCreateFile() {
        Facture__c facture = [SELECT Id FROM Facture__c LIMIT 1];
        User authorizedUser = createAuthorizedUser();
        Test.setMock(HttpCalloutMock.class, new EncryptionMock(true));

        System.runAs(authorizedUser) {
            Test.startTest();
            TB2SI_ProtectedInvoicePdfController.startGeneration(facture.Id);
            Test.stopTest();
        }

        Facture__c saved;
        Integer linkedFiles;
        System.runAs(authorizedUser) {
            saved = [SELECT Protected_PDF_Status__c, Protected_PDF_File_Id__c, Protected_PDF_Error__c FROM Facture__c WHERE Id = :facture.Id];
            linkedFiles = [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :facture.Id];
        }
        System.assertEquals('Failed', saved.Protected_PDF_Status__c);
        System.assertEquals(null, saved.Protected_PDF_File_Id__c);
        System.assert(saved.Protected_PDF_Error__c.contains('HTTP 500'));
        System.assertEquals(0, linkedFiles);
    }

    @IsTest
    static void completedInvoiceIsIdempotent() {
        Facture__c facture = [SELECT Id FROM Facture__c LIMIT 1];
        User authorizedUser = createAuthorizedUser();
        facture.Protected_PDF_Status__c = 'Succeeded';
        facture.Protected_PDF_File_Id__c = '069000000000001AAA';
        Database.update(facture, AccessLevel.SYSTEM_MODE);

        TB2SI_ProtectedInvoicePdfController.StartResult result;
        System.runAs(authorizedUser) {
            result = TB2SI_ProtectedInvoicePdfController.startGeneration(facture.Id);
        }

        System.assertEquals('Succeeded', result.status);
        System.assertEquals('069000000000001AAA', result.fileId);
    }

    @IsTest
    static void missingInvoiceCannotBeRead() {
        User authorizedUser = createAuthorizedUser();
        try {
            System.runAs(authorizedUser) {
                TB2SI_ProtectedInvoicePdfController.startGeneration(Id.valueOf('a00000000000000AAA'));
            }
            System.assert(false, 'Une facture inexistante doit être refusée.');
        } catch (QueryException expected) {
            System.assert(true);
        }
    }

    private static User createAuthorizedUser() {
        User current = [SELECT Id, ProfileId FROM User WHERE Id = :UserInfo.getUserId()];
        String unique = String.valueOf(DateTime.now().getTime()) + EncodingUtil.convertToHex(Crypto.generateAESKey(128)).substring(0, 8);
        User authorized = new User(
            Alias = 'pdfusr',
            Email = 'protected-pdf-' + unique + '@example.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Protected PDF',
            LanguageLocaleKey = 'fr',
            LocaleSidKey = 'fr_FR',
            ProfileId = current.ProfileId,
            TimeZoneSidKey = 'Europe/Paris',
            Username = 'protected-pdf-' + unique + '@example.test'
        );
        System.runAs(current) {
            insert authorized;
        }
        PermissionSet permissions = [SELECT Id FROM PermissionSet WHERE Name = 'TB2SI_ProtectedInvoicePdf' LIMIT 1];
        System.runAs(current) {
            insert new PermissionSetAssignment(AssigneeId = authorized.Id, PermissionSetId = permissions.Id);
        }
        return authorized;
    }

    private class EncryptionMock implements HttpCalloutMock {
        private final Boolean fail;
        EncryptionMock(Boolean fail) { this.fail = fail; }

        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('POST', request.getMethod());
            System.assertEquals('callout:TB2SI_PdfEncryption/v1/pdf/encrypt', request.getEndpoint());
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(request.getBody());
            System.assert(String.isNotBlank((String) payload.get('pdfBase64')));
            System.assertNotEquals((String) payload.get('userPassword'), (String) payload.get('ownerPassword'));

            HttpResponse response = new HttpResponse();
            if (fail) {
                response.setStatusCode(500);
                response.setBody('{"error":"encryption failed"}');
            } else {
                response.setStatusCode(200);
                response.setHeader('Content-Type', 'application/json');
                response.setBody(JSON.serialize(new Map<String, Object>{
                    'pdfBase64' => EncodingUtil.base64Encode(Blob.valueOf('%PDF-1.7 protected test invoice'))
                }));
            }
            return response;
        }
    }
}
