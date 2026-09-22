@isTest
public with sharing class YS_Service_Test {
    @isTest
    private static void testGetNameCredentials() {
        // Test data setup
        String testName = 'testGetNameCredentials';
        YS_Configuration__c orgDefault = YS_Configuration__c.getOrgDefaults();
        orgDefault.IsSandbox__c = true;
        upsert orgDefault;
        
        // Actual test
        Test.startTest();
        Assert.areEqual('YS_Sandbox', YS_Service.getNameCredentials(), testName + ' #1 > Expected sandbox credentials');
        orgDefault.IsSandbox__c = false;
        update orgDefault;
        Assert.areEqual('YS_Prod', YS_Service.getNameCredentials(), testName + ' #2 > Expected production credentials');
        Test.stopTest();
    }

    @isTest
    private static void testGetEncodingKey() {
        // Test data setup
        String testName = 'testGetEncodingKey';
        YS_Configuration__c orgDefault = YS_Configuration__c.getOrgDefaults();
        orgDefault.YS_EncodingKey__c = 'myEncodingKey';
        upsert orgDefault;
        
        // Actual test
        Test.startTest();
        Assert.areEqual('myEncodingKey', YS_Service.getEncodingKey(), testName + ' #1 > Unexpected Encoding Key');
        Test.stopTest();
    }

    @isTest
    private static void testGetEndpoint() {
        // Test data setup
        String testName = 'testGetEndpoint';
        YS_Configuration__c orgDefault = YS_Configuration__c.getOrgDefaults();
        orgDefault.IsSandbox__c = true;
        upsert orgDefault;
        
        // Actual test
        Test.startTest();
        Assert.areEqual('callout:YS_Sandbox/v3/endpoint', YS_Service.getEndpoint('/endpoint', null), testName + ' #1 > Unexpected enpoint (null params)');
        Assert.areEqual('callout:YS_Sandbox/v3/endpoint', YS_Service.getEndpoint('/endpoint', new List<String>()), testName + ' #2 > Unexpected enpoint (no params)');
        Assert.areEqual('callout:YS_Sandbox/v3/endpoint/{0}', YS_Service.getEndpoint('/endpoint/{0}', null), testName + ' #3 > Unexpected enpoint');
        Assert.areEqual('callout:YS_Sandbox/v3/endpoint/variable1', YS_Service.getEndpoint('/endpoint/{0}', new List<String> { 'variable1' }), testName + ' #4 > Unexpected enpoint with param');
        Test.stopTest();
    }

    @isTest
    private static void testGetTimeout() {
        // Test data setup
        String testName = 'testGetTimeout';
        
        // Actual test
        Test.startTest();
        Assert.areEqual(YS_Service.TIMEOUT, YS_Service.getTimeout(), testName + ' #1 > Unexpected default timeout');
        Test.stopTest();
    }

    @isTest
    private static void testConstructRequest() {
        // Test data setup
        String testName = 'testConstructRequest';
        
        // Actual test
        Test.startTest();
        HttpRequest req = YS_Service.constructRequest('GET', '/endpoint/{0}', new List<String> { 'variable1' });
        Test.stopTest();

        // Asserts
        Assert.areEqual('GET', req.getMethod(), testName + ' #1 > Unexpected method');
        Assert.areEqual('callout:YS_Prod/v3/endpoint/variable1', req.getEndpoint(), testName + ' #2 > Unexpected endpoint');
    }
}