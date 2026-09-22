@isTest
public with sharing class YS_Utils_Test {

    @isTest
    public static void testInsertFuture() {
        String testName = 'testInsertFuture';
        List<YS_Utils.WrappedException> lstErrToInsert = new List<YS_Utils.WrappedException>();

        for(integer i = 0 ; i < 20 ; i ++)
        {
            lstErrToInsert.add(new YS_Utils.WrappedException('ErrorMessage-'+i, 'ErrorSource-'+i));
        }
        Assert.areEqual(20, lstErrToInsert.size(), testName + ' #0 > Wrong list size');

        Test.startTest();
            YS_Utils.insertExceptionsAsLogs(lstErrToInsert, true);
        Test.stopTest();

        /* ! PLEASE CUSTOMIZE THIS METHOD ONCE THE UTILS CLASS IS CUSTOMIZED !
        List<Log__c> errorInserted = [SELECT Id, Type__c, ErrorMessage__c, Source__c FROM Log__c];
        Assert.areEqual(20, errorInserted.size(), testName + ' #1 > Wrong number of inserted ErrorLogs');
        for(integer i = 0 ; i < 20 ; i++)
        {
            Assert.areEqual('Error', errorInserted[i].Type__c, testName + ' #2.0 > Wrong Type');
            Assert.areEqual(lstErrToInsert[i].ErrorMessage__c, errorInserted[i].ErrorMessage__c, testName + ' #2.1 > Wrong ErrorMessage');
            Assert.areEqual(lstErrToInsert[i].Source__c, errorInserted[i].Source__c, testName + ' #2.3 > Wrong source');
        }
        */
    }
    
    @isTest
    public static void testExceptionLogic() {
        String testName = 'testExceptionLogic';
        try {
            try {
                throw new YS_Utils.WrappedException('message', 'source');
            } catch (YS_Utils.WrappedException e) {
                Assert.areEqual('message', e.getMessage(), testName + ' #1 > Wrong Error Message');
                throw new YS_Utils.WrappedException(e, e.getStackTraceString());
            }
        } catch (YS_Utils.WrappedException e) {
            Assert.areEqual('message', e.getMessage(), testName + ' #2 > Wrong Error Message');
            Assert.areEqual(e.errorSource, e.getStackTraceString(), testName + ' #3 > Wrong Error Source');
            e.toErrorLog(); // do nothing at the moment, need customization for each organization
        }
    }

    public class TestDataValidation extends YS_Utils.DataValidationAbstract
    {
        String mandatoryString;
        String optionalString;
        List<String> mandatoryArray;
        List<String> optionalArray;

        public void checkValidity()
        {
            super.checkValidity(new Set<String>{'mandatoryString','mandatoryArray'}, 'TestDataValidation');
        }
    }

    @isTest
    public static void testDataValidation()
    {
        String testName = 'testDataValidation';
        TestDataValidation data = new TestDataValidation();
        try {
            data.checkValidity();
        } catch(YS_Utils.WrappedException e)
        {
            Assert.isTrue(e.getMessage().contains('ERR_MISSING_PROPERTIES'), testName + ' #1.1 > Wrong message, expected ERR_MISSING_PROPERTIES, got ' + e.getMessage());
            Assert.isTrue(e.getMessage().contains('mandatoryString'), testName + ' #1.2 > Wrong message, expected mandatoryString, got ' + e.getMessage());
            Assert.isTrue(e.getMessage().contains('mandatoryArray'), testName + ' #1.3 > Wrong message, expected mandatoryArray, got ' + e.getMessage());
            Assert.isFalse(e.getMessage().contains('optionalString'), testName + ' #1.4 > Wrong message, optionalString should not be considered as missing property, original message : ' + e.getMessage());
            Assert.isFalse(e.getMessage().contains('optionalArray'), testName + ' #1.5 > Wrong message, optionalArray should not be considered as missing property, original message : ' + e.getMessage());
        }
        data.mandatoryString = 'toto';
        data.mandatoryArray = new List<String>();
        try {
            data.checkValidity();
        } catch(YS_Utils.WrappedException e)
        {
            Assert.isTrue(e.getMessage().contains('ERR_MISSING_PROPERTIES'), testName + ' #2.1 > Wrong message, expected ERR_MISSING_PROPERTIES, got ' + e.getMessage());
            Assert.isTrue(e.getMessage().contains('mandatoryArray'), testName + ' #2.2 > Wrong message, expected mandatoryArray, got ' + e.getMessage());
            Assert.isFalse(e.getMessage().contains('mandatoryString'), testName + ' #2.3 > Wrong message, mandatoryString should not be considered as missing property, original message : ' + e.getMessage());
            Assert.isFalse(e.getMessage().contains('optionalString'), testName + ' #2.4 > Wrong message, optionalString should not be considered as missing property, original message : ' + e.getMessage());
            Assert.isFalse(e.getMessage().contains('optionalArray'), testName + ' #2.5 > Wrong message, optionalArray should not be considered as missing property, original message : ' + e.getMessage());
        }

        data.mandatoryArray.add('element');
        data.checkValidity(); // no exception should be raised here
    }
}