@isTest
public with sharing class YS_MultipartUtil_Test {

    @isTest
    private static void testGetContentType() {
        // Test data setup
        String testName = 'testGetContentType';

        // Actual test
        Test.startTest();
        String res = YS_MultipartUtil.getContentType();
        String boundary = YS_MultipartUtil.getBoundary();
        Test.stopTest();

        // Assert
        Assert.areEqual('multipart/form-data; charset="UTF-8"; boundary="' + boundary + '"', res, testName + ' #1 > Unexpected content type');
    }

    @isTest
    private static void testSafelyPad() {
        // Test data setup
        String testName = 'testSafelyPad';
        String lineBreak = '\r\n';
        Map<String, String> testValues = new Map<String, String> {
            'bonjour' => 'bonjour\r\n',
            'bonjour\r\n' => 'bonjour\r\n',
            'Man' => 'Man \r\n', // 2 paddings
            'Ma' => 'Ma  \r\n', // 1 padding
            'M' => 'M\r\n' // no additionnal padding
        };

        // Actual test
        Integer count = 0;
        Test.startTest();
        for (String key: testValues.keySet())
        {
            Boolean encode = key.startsWith('M');
            // Asserts
            String res = YS_MultipartUtil.safelyPad(key, '\r\n', encode);
            Assert.areEqual(testValues.get(key), encode ? EncodingUtil.base64Decode(res).toString() : res, testName + ' #' + ++count + ' > Unexpected result');
        }
        Test.stopTest();
    }

    @isTest
    private static void testWriteBoundary() {
        // Test data setup
        String testName = 'testWriteBoundary';

        // Actual test
        Test.startTest();
        String res = YS_MultipartUtil.writeBoundary(false);
        String resEncoded = YS_MultipartUtil.writeBoundary(true);
        String boundary = YS_MultipartUtil.getBoundary();
        Test.stopTest();

        // Assert
        Assert.isTrue(res.startsWith('--' + boundary), testName + ' #1 > Unexpected boundary');
        Assert.isTrue(EncodingUtil.base64Decode(resEncoded).toString().startsWith('--' + boundary), testName + ' #2 > Unexpected encoded boundary');
        Assert.isFalse(resEncoded.endsWith('='), testName + ' #3 > Encoded boundary should not be padded');
    }

    @isTest
    private static void testWriteEndingBoundary() {
        // Test data setup
        String testName = 'testWriteEndingBoundary';

        // Actual test
        Test.startTest();
        String res = YS_MultipartUtil.writeEndingBoundary(false);
        String resEncoded = YS_MultipartUtil.writeEndingBoundary(true);
        String boundary = YS_MultipartUtil.getBoundary();
        Test.stopTest();

        // Assert
        Assert.areEqual('--' + boundary + '--' , res, testName + ' #1 > Unexpected ending boundary');
        Assert.areEqual('--' + boundary + '--', EncodingUtil.base64Decode(resEncoded).toString(), testName + ' #2 > Unexpected encoded ending boundary');
        Assert.isFalse(resEncoded.endsWith('='), testName + ' #3 > Encoded ending boundary should not be padded');
    }

    @isTest
    private static void testWriteBodyParameter() {
        // Test data setup
        String testName = 'testWriteBodyParameter';

        // Actual test
        Test.startTest();
        String res = YS_MultipartUtil.writeBodyParameter('fromage', 'raclette', false);
        Test.stopTest();

        // Assert
        Assert.areEqual('Content-Disposition: form-data; name="fromage"\r\n\r\nraclette\r\n', res, testName + ' #1 > Unexpected body parameter');
    }

    @isTest
    private static void testWriteFileBodyParameter() {
        // Test data setup
        String testName = 'testWriteFileBodyParameter';
        List<String> fileContent = new List<String> {
            EncodingUtil.base64Encode(Blob.valueOf('Man')),
            EncodingUtil.base64Encode(Blob.valueOf('Ma')),
            EncodingUtil.base64Encode(Blob.valueOf('M'))
        };
        String beforefile = 'Content-Disposition: form-data; name="file"; filename="file.pdf"\r\n';
        beforefile += 'Content-Type: application/pdf\r\n\r\n';

        // Actual test
        Test.startTest();
        Integer count=0;
        for (String content: fileContent) {
            YS_MultipartUtil.FileParamResponse res = YS_MultipartUtil.writeFileBodyParameter('file', content, 'file.pdf', false);
            
            // Asserts
            Assert.isFalse(res.file.endsWith('='), testName + ' #1.' + count + ' > the file should not be padded to avoid file corruption');
            Assert.areEqual(beforeFile, res.before, testName + ' #2.'+ ++count + ' > Unexpected body parameter');
        }
        Test.stopTest();
    }

    @isTest
    private static void testResolveMimeType() {
        // Test data setup
        String testName = 'testResolveMimeType';

        // Actual test
        Test.startTest();
        String res1 = YS_MultipartUtil.resolveMimeType('file.pdf');
        String res2 = YS_MultipartUtil.resolveMimeType('file.PDF');
        YS_Utils.WrappedException eThrown;
        try {
            YS_MultipartUtil.resolveMimeType('file.png');
            Assert.fail(testName + ' #0.1 > Should have thrown an exception as png files are not supported');
        }
        catch(YS_Utils.WrappedException e)
        {
            eThrown = e;
        }
        catch(Exception e)
        {
            Assert.fail(testName + ' #0.2 > Wrong type of exception thrown');
        }
        Test.stopTest();

        // Asserts
        Assert.areEqual('application/pdf', res1, testName + ' #1 > Unexpected mime type');
        Assert.areEqual('application/pdf', res2, testName + ' #2 > Unexpected mime type');
        Assert.areEqual(YS_MultipartUtil.CLASS_NAME, eThrown.errorSource, testName + ' #3 > Wrong error source');
        Assert.isTrue(eThrown.getMessage().contains('Unsupported file type: png'), testName + ' #4 > Wrong error message');
    }
}