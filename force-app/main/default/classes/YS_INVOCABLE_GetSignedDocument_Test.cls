@isTest
public with sharing class YS_INVOCABLE_GetSignedDocument_Test {

    @isTest
    private static void testGetDocuments() {
        // Test data setup
        String testName = 'testGetDocuments';

        YS_SignatureRequest__c sr = YS_DataTestFactory.createSignatureRequest();
        insert sr;

        // Actual test
        Test.setMock(HttpCalloutMock.class, new YS_GetSignedDocumentMockCallout());
        Test.startTest();
        try
        {
            YS_INVOCABLE_GetSignedDocument.Response response = YS_INVOCABLE_GetSignedDocument.getDocuments(new List<String>()).get(0);
            Assert.fail(testName + ' #0.1 > exception should be thrown before');
        }
        catch (YS_Utils.WrappedException ie) {
            Assert.areEqual(YS_Utils.ERR_UNSUPORTED_DATA, ie.getMessage(), testName + ' #0.2 > Unexpected exception');
        }
        catch (Exception e) {
            Assert.fail(testName + ' #0.3 > Unexpected exception');
        }
        YS_INVOCABLE_GetSignedDocument.Response response = YS_INVOCABLE_GetSignedDocument.getDocuments(new List<String> { sr.ExternalId__c }).get(0);
        Test.stopTest();
    
        // Asserts
        // verify response
        Assert.isTrue(response.success, testName + ' #1 > the callout should be successfull');
        Assert.areEqual(200, response.statusCode, testName + ' #2 > unexpected Status Code');
        Assert.isNull(response.errorMessage, testName + ' #3 > There should not be any error message');

        // verify Downloaded document
        List<ContentDocumentLink> cdls = [SELECT Id, ContentDocument.Title, ContentDocument.LatestPublishedVersion.VersionData FROM ContentDocumentLink WHERE LinkedEntityId = :sr.Id];
        Assert.areEqual(1, cdls.size(), testName + ' #4 > there should be only 1 Content Document Linked to the Quote');
        ContentVersion cv = YS_DataTestFactory.createContentVersion();
        Assert.areEqual(cv.Title, cdls[0].ContentDocument.Title, testName + ' #5.1 > unexpected content title');
        Assert.areEqual(cv.VersionData.toString(), cdls[0].ContentDocument.LatestPublishedVersion.VersionData.toString(), testName + ' #5.2 > unexpected content body');
    }

    @isTest
    private static void testDoRestCall_Error429() {
        // Test data setup
        String testName = 'testDoRestCall_Error429';
        String signatureRequestId = '99999999-9999-9999-9999-999999999999';

        // Actual test
        Test.setMock(HttpCalloutMock.class, new YS_GetSignedDocumentMockCallout());
        Test.startTest();
        YS_INVOCABLE_GetSignedDocument.Response response = YS_INVOCABLE_GetSignedDocument.getDocuments(new List<String> { signatureRequestId }).get(0);
        Test.stopTest();
    
        // Asserts
        Assert.isFalse(response.success, testName + ' #1 > the callout should not be successfull');
        Assert.areEqual(429, response.statusCode, testName + ' #2 > unexpected Status Code');
        Assert.areEqual('too many requests', response.errorMessage, testName + ' #3 > Unexpected error message');
    }

    @isTest
    private static void testDoRestCall_ErrorUnhandled() {
        // Test data setup
        String testName = 'testDoRestCall_ErrorUnhandled';

        // Actual test
        Test.setMock(HttpCalloutMock.class, new YS_GetSignedDocumentMockCallout());
        Test.startTest();
        YS_INVOCABLE_GetSignedDocument.Response response = YS_INVOCABLE_GetSignedDocument.getDocuments(new List<String> { 'abcd' }).get(0);
        Test.stopTest();
    
        // Asserts
        // verify response
        Assert.isFalse(response.success, testName + ' #1 > the callout should not be successfull');
        Assert.isNull(response.statusCode, testName + ' #2 > No Status Code should be returned as the call should not occur');
        Assert.areEqual('List has no rows for assignment to SObject', response.errorMessage, testName + ' #3 > Unexpected error message');
    }

    @isTest
    private static void testResponseErrorCodes() {
        // Test data setup
        String testName = 'testResponseErrorCodes';
        ExternalService.YS_ViolationResponse body400 = new ExternalService.YS_ViolationResponse();
        body400.detail_set = true;
        body400.detail = 'Bad Request';
        ExternalService.YS_getx5fsignaturex5frequestsx5f401x5fresponse body401 = new ExternalService.YS_getx5fsignaturex5frequestsx5f401x5fresponse();
        body401.detail = 'Unauthorized';
        YS_INVOCABLE_GetSignedDocument.Response response;
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        // Actual test
        Test.startTest();
        res.setStatusCode(400);
        res.setBody(JSON.serialize(body400));
        response = new YS_INVOCABLE_GetSignedDocument.Response(res);
        Assert.isFalse(response.success, testName + ' #1.1 > unexpected success value (code 400)');
        Assert.areEqual(400, response.statusCode, testName + ' #1.2 > unexpected statusCode value (code 400)');
        Assert.areEqual('Bad Request', response.errorMessage, testName + ' #1.4 > unexpected errorMessage value (code 400)');
        
        res.setStatusCode(401);
        res.setBody(JSON.serialize(body401));
        response = new YS_INVOCABLE_GetSignedDocument.Response(res);
        Assert.isFalse(response.success, testName + ' #1.1 > unexpected success value (code 401)');
        Assert.areEqual(401, response.statusCode, testName + ' #1.2 > unexpected statusCode value (code 401)');
        Assert.areEqual('Unauthorized', response.errorMessage, testName + ' #1.4 > unexpected errorMessage value (code 401)');
        
        res.setStatusCode(404);
        res.setBody('{}');
        response = new YS_INVOCABLE_GetSignedDocument.Response(res);
        Assert.isFalse(response.success, testName + ' #1.1 > unexpected success value (code 404)');
        Assert.areEqual(404, response.statusCode, testName + ' #1.2 > unexpected statusCode value (code 404)');
        Assert.areEqual('Resource not found', response.errorMessage, testName + ' #1.4 > unexpected errorMessage value (code 404)');
        Test.stopTest();
    }

    private class YS_GetSignedDocumentMockCallout implements HttpCalloutMock {
        private final String ENDPOINT_REGEX = '.*\\/v3\\/signature_requests\\/[a-fA-F0-9\\-]*\\/documents\\/download';
        private final String ENDPOINT_ERROR_REGEX = '.*\\/v3\\/signature_requests\\/[9\\-]*\\/documents\\/download';
        private final String BODY_FILE_CONTENT = '\r\nThis is really Nice, and i am not talking about the city\r\n';
        private final String MOCKNAME = 'YS_GetSignedDocumentMockCallout';

        public HTTPResponse respond(HTTPRequest req) {
            // check endpoint
            Pattern MyPattern = Pattern.compile(ENDPOINT_REGEX);
            Matcher MyMatcher = MyPattern.matcher(req.getEndpoint());
            
            // You can use the system static method assert to verify the match
            Assert.isTrue(MyMatcher.matches(), MOCKNAME + ' #1 > unexpected endpoint: ' + req.getEndpoint());
            Assert.areEqual('GET', req.getMethod(), MOCKNAME + ' #2 > unexpected method');

            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/pdf');
            
            MyPattern = Pattern.compile(ENDPOINT_ERROR_REGEX);
            MyMatcher = MyPattern.matcher(req.getEndpoint());
            if (MyMatcher.matches())
            {
                // if error
                res.setBody('{}');
                res.setStatusCode(429);
                res.setStatus('too many requests');
            }
            else
            {
                // if success
                ContentVersion cv = YS_DataTestFactory.createContentVersion();
                res.setHeader('Content-Disposition', 'attachment; filename=' + cv.PathOnClient + '; filename*=utf-8\'\'' + EncodingUtil.urlEncode(cv.PathOnClient, 'UTF-8'));
                res.setBodyAsBlob(cv.VersionData);
                res.setStatusCode(200);
            }
            return res;
        }
    }
}