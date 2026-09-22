@isTest
public with sharing class YS_INVOCABLE_UploadDocument_Test {
    
    @isTest
    private static void testDoRestCall() {
        // Test data setup
        String testName = 'testDoRestCall';
        ContentVersion cv = YS_DataTestFactory.createContentVersion();
        insert cv;
        YS_INVOCABLE_UploadDocument.UploadDocumentData input = new YS_INVOCABLE_UploadDocument.UploadDocumentData();
        input.signatureRequestId = '01234567-abcd-abcd-abcd-a9e73a872796';
        input.fileId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        input.nature = 'signable_document';
        input.useSmartAnchors = true;

        // Actual test
        Test.setMock(HttpCalloutMock.class, new YS_UploadDocumentMockCallout());
        Test.startTest();
        YS_INVOCABLE_UploadDocument.Response response = YS_INVOCABLE_UploadDocument.doRestCall(new List<YS_INVOCABLE_UploadDocument.UploadDocumentData> { input }).get(0);
        Test.stopTest();
    
        // Asserts
        Assert.isTrue(response.success, testName + ' #1 > the callout should be successfull');
        Assert.areEqual(201, response.statusCode, testName + ' #2 > unexpected Status Code');
        Assert.isNull(response.errorMessage, testName + ' #3 > There should not be any error message');
        ExternalService.YS_Document result = response.yousignDocument;
        Assert.areEqual('89120884-d29a-4b1a-ac7b-a9e73a872796', response.yousignDocument.id, testName + ' #4.1 unexpected value for yousignDocument.id');
        Assert.areEqual('documenttobesigned.pdf', response.yousignDocument.filename, testName + ' #4.2 unexpected value for yousignDocument.filename');
        Assert.areEqual('signable_document', response.yousignDocument.nature, testName + ' #4.3 unexpected value for yousignDocument.nature');
        Assert.areEqual('application/pdf', response.yousignDocument.contentx5ftype, testName + ' #4.4 unexpected value for yousignDocument.content_type');
        Assert.isTrue(response.yousignDocument.isx5fsigned, testName + ' #4.5 unexpected value for yousignDocument.is_signed');
        Assert.areEqual(1, response.yousignDocument.totalx5fpages, testName + ' #4.6 unexpected value for yousignDocument.total_pages');
        Assert.areEqual(2, response.yousignDocument.totalx5fanchors, testName + ' #4.7 unexpected value for yousignDocument.total_anchors');
    }

    @isTest
    private static void testDoRestCall_Error429() {
        // Test data setup
        String testName = 'testDoRestCall_Error429';
        ContentVersion cv = YS_DataTestFactory.createContentVersion();
        insert cv;
        YS_INVOCABLE_UploadDocument.UploadDocumentData input = new YS_INVOCABLE_UploadDocument.UploadDocumentData();
        input.signatureRequestId = '99999999-9999-9999-9999-999999999999';
        input.fileId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        input.nature = 'signable_document';
        input.useSmartAnchors = true;

        // Actual test
        Test.setMock(HttpCalloutMock.class, new YS_UploadDocumentMockCallout());
        Test.startTest();
        YS_INVOCABLE_UploadDocument.Response response = YS_INVOCABLE_UploadDocument.doRestCall(new List<YS_INVOCABLE_UploadDocument.UploadDocumentData> { input }).get(0);
        Test.stopTest();
    
        // Asserts
        Assert.isFalse(response.success, testName + ' #1 > the callout should not be successfull');
        Assert.areEqual(429, response.statusCode, testName + ' #2 > unexpected Status Code');
        Assert.areEqual('too many requests', response.errorMessage, testName + ' #3 > Unexpected error message');
        Assert.isNull(response.yousignDocument, testName + ' #4 > There should not be any yousign document');
    }

    @isTest
    private static void testDoRestCall_ErrorUnhandled() {
        // Test data setup
        String testName = 'testDoRestCall_ErrorUnhandled';

        YS_INVOCABLE_UploadDocument.UploadDocumentData input = new YS_INVOCABLE_UploadDocument.UploadDocumentData();
        input.signatureRequestId = '01234567-abcd-abcd-abcd-a9e73a872796';
        input.fileId = 'ThisIsNotAFileId';
        input.nature = 'signable_document';
        input.useSmartAnchors = true;

        // Actual test
        Test.setMock(HttpCalloutMock.class, new YS_UploadDocumentMockCallout());
        Test.startTest();
        YS_INVOCABLE_UploadDocument.Response response = YS_INVOCABLE_UploadDocument.doRestCall(new List<YS_INVOCABLE_UploadDocument.UploadDocumentData> { input }).get(0);
        Test.stopTest();
    
        // Asserts
        Assert.isFalse(response.success, testName + ' #1 > the callout should not be successfull');
        Assert.isNull(response.statusCode, testName + ' #2 > No Status Code should be returned as the call should not occur');
        Assert.areEqual('List has no rows for assignment to SObject', response.errorMessage, testName + ' #3 > Unexpected error message');
        Assert.isNull(response.yousignDocument, testName + ' #4 > There should not be any yousign document');
    }

    @isTest
    private static void testInputValidity() {
        // Test data setup
        String testName = 'testInputValidity';

        YS_INVOCABLE_UploadDocument.UploadDocumentData input = new YS_INVOCABLE_UploadDocument.UploadDocumentData();
        input.fileId = 'ThisIsNotAFileId';
        input.nature = 'signable_document';
        
        // Actual test
        Test.startTest();
        try {
            input.checkValidity();
            Assert.fail(testName + ' #1.1 > signatureRequestId should be mandatory');
        }
        catch(YS_Utils.WrappedException e)
        {
            Assert.areEqual(YS_Utils.ERR_NULL_PARAM, e.getMessage(), testName + ' #1.2 > Unexpected error message');
        }
        catch(Exception e)
        {
            Assert.fail(testName + ' #1.3 > Unexpected exception: ' + e.getMessage());
        }
        
        input.signatureRequestId = '01234567-abcd-abcd-abcd-a9e73a872796';
        input.fileId = null;
        try {
            input.checkValidity();
            Assert.fail(testName + ' #2.1 > fileId should be mandatory');
        }
        catch(YS_Utils.WrappedException e)
        {
            Assert.areEqual(YS_Utils.ERR_NULL_PARAM, e.getMessage(), testName + ' #2.2 > Unexpected error message');
        }
        catch(Exception e)
        {
            Assert.fail(testName + ' #2.3 > Unexpected exception: ' + e.getMessage());
        }

        input.fileId = 'ThisIsNotAFileId';
        input.nature = '';
        try {
            input.checkValidity();
            Assert.fail(testName + ' #3.1 > nature should be mandatory');
        }
        catch(YS_Utils.WrappedException e)
        {
            Assert.areEqual(YS_Utils.ERR_NULL_PARAM, e.getMessage(), testName + ' #3.2 > Unexpected error message');
        }
        catch(Exception e)
        {
            Assert.fail(testName + ' #3.3 > Unexpected exception: ' + e.getMessage());
        }
        
        input.nature = 'signable_document';
        input.checkValidity();
        Test.stopTest();
    
        // Asserts
        Assert.isFalse(input.useSmartAnchors, testName + ' #4 > Smart anchors should be defaulted to false');
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
        YS_INVOCABLE_UploadDocument.Response response;
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        // Actual test
        Test.startTest();
        res.setStatusCode(400);
        res.setBody(JSON.serialize(body400));
        response = new YS_INVOCABLE_UploadDocument.Response(res);
        Assert.isFalse(response.success, testName + ' #1.1 > unexpected success value (code 400)');
        Assert.areEqual(400, response.statusCode, testName + ' #1.2 > unexpected statusCode value (code 400)');
        Assert.isNull(response.yousignDocument, testName + ' #1.3 > unexpected yousignDocument value (code 400)');
        Assert.areEqual('Bad Request', response.errorMessage, testName + ' #1.4 > unexpected errorMessage value (code 400)');
        
        res.setStatusCode(401);
        res.setBody(JSON.serialize(body401));
        response = new YS_INVOCABLE_UploadDocument.Response(res);
        Assert.isFalse(response.success, testName + ' #1.1 > unexpected success value (code 401)');
        Assert.areEqual(401, response.statusCode, testName + ' #1.2 > unexpected statusCode value (code 401)');
        Assert.isNull(response.yousignDocument, testName + ' #1.3 > unexpected yousignDocument value (code 401)');
        Assert.areEqual('Unauthorized', response.errorMessage, testName + ' #1.4 > unexpected errorMessage value (code 401)');
        
        res.setStatusCode(403);
        res.setBody('{}');
        response = new YS_INVOCABLE_UploadDocument.Response(res);
        Assert.isFalse(response.success, testName + ' #1.1 > unexpected success value (code 403)');
        Assert.areEqual(403, response.statusCode, testName + ' #1.2 > unexpected statusCode value (code 403)');
        Assert.isNull(response.yousignDocument, testName + ' #1.3 > unexpected yousignDocument value (code 403)');
        Assert.areEqual('Access forbidden', response.errorMessage, testName + ' #1.4 > unexpected errorMessage value (code 403)');
        
        res.setStatusCode(404);
        res.setBody('{}');
        response = new YS_INVOCABLE_UploadDocument.Response(res);
        Assert.isFalse(response.success, testName + ' #1.1 > unexpected success value (code 404)');
        Assert.areEqual(404, response.statusCode, testName + ' #1.2 > unexpected statusCode value (code 404)');
        Assert.isNull(response.yousignDocument, testName + ' #1.3 > unexpected yousignDocument value (code 404)');
        Assert.areEqual('Resource not found', response.errorMessage, testName + ' #1.4 > unexpected errorMessage value (code 404)');
        Test.stopTest();
    }

    private class YS_UploadDocumentMockCallout implements HttpCalloutMock {
        private final String ENDPOINT_REGEX = '.*\\/v3\\/signature_requests\\/[a-fA-F0-9\\-]*\\/documents';
        private final String ENDPOINT_ERROR_REGEX = '.*\\/v3\\/signature_requests\\/[9\\-]*\\/documents';
        private final String BODY_NATURE = '\r\nContent-Disposition: form-data; name="nature"\r\n\r\nsignable_document\r\n';
        private final String BODY_SMART_ANCHORS = '\r\nContent-Disposition: form-data; name="parse_anchors"\r\n\r\ntrue\r\n';
        private final String BODY_FILE = '\r\nContent-Disposition: form-data; name="file"; filename="ReallyNiceDocument.pdf"\r\nContent-Type: application/pdf\r\n';
        private final String BODY_FILE_CONTENT = '\r\nThis is really Nice, and i am not talking about the French city\r\n';
        private final String MOCKNAME = 'YS_UploadDocumentMockCallout';

        public HTTPResponse respond(HTTPRequest req) {
            // check endpoint
            Pattern MyPattern = Pattern.compile(ENDPOINT_REGEX);
            Matcher MyMatcher = MyPattern.matcher(req.getEndpoint());
            
            // You can use the system static method assert to verify the match
            Assert.isTrue(MyMatcher.matches(), MOCKNAME + ' #1 > unexpected endpoint: ' + req.getEndpoint());
            Assert.areEqual('POST', req.getMethod(), MOCKNAME + ' #2 > unexpected method');
            Assert.isTrue(req.getBody().contains(BODY_NATURE), MOCKNAME + ' #3 > Missing nature parameter');
            Assert.isTrue(req.getBody().contains(BODY_SMART_ANCHORS), MOCKNAME + ' #4 > Missing smart anchors parameter');
            Assert.isTrue(req.getBody().contains(BODY_FILE), MOCKNAME + ' #5 > Missing file parameter');
            Assert.isTrue(req.getBody().contains(BODY_FILE_CONTENT), MOCKNAME + ' #6 > Missing file content');

            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
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
                ExternalService.YS_Document result = new ExternalService.YS_Document();
                result.id = '89120884-d29a-4b1a-ac7b-a9e73a872796';
                result.filename = 'documenttobesigned.pdf';
                result.nature = 'signable_document';
                result.contentx5ftype = 'application/pdf';
                result.isx5fsigned = true;
                result.totalx5fpages = 1;
                result.totalx5fanchors = 2;
                res.setBody(JSON.serialize(result).replaceAll('x5f', '_'));
                res.setStatusCode(201);
            }
            return res;
        }
    }
}