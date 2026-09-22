/**
 * @description       : Test class for YS_INVOCABLE_VisualForceToPDF
 * @author            : ctixier
 * @group             : UTIL-INVOCABLE
 * @last modified on  : 2022-07-01
 * @last modified by  : ctixier
**/
@isTest
public with sharing class YS_INVOCABLE_VisualForceToPDF_Test {
    @isTest
    public static void testWrongParams()
    {
        String testName = 'testWrongParams';

        Test.startTest();
        try
        {
            YS_INVOCABLE_VisualForceToPDF.generatePDF(null);
            Assert.fail(testName + ' #1 > An Exception should have been fired');
        }
        catch(YS_Utils.WrappedException e)
        {
            Assert.areEqual(e.getMessage(), YS_Utils.ERR_NULL_PARAM, testName + ' #1.1 > Expected ERR_NULL_PARAM Exception, got ' + e.getMessage());
            Assert.areEqual(e.errorSource, YS_INVOCABLE_VisualForceToPDF.CLASS_NAME, testName + ' #1.2 > Unexpected error source, got ' + e.errorSource);
        }

        try
        {
            YS_INVOCABLE_VisualForceToPDF.VisualForceToPDFInput input = new YS_INVOCABLE_VisualForceToPDF.VisualForceToPDFInput();
            
            YS_INVOCABLE_VisualForceToPDF.generatePDF(new List<YS_INVOCABLE_VisualForceToPDF.VisualForceToPDFInput>{input, input});
            Assert.fail(testName + ' #2 > An Exception should have been fired');
        }
        catch(YS_Utils.WrappedException e)
        {
            Assert.areEqual(e.getMessage(), YS_Utils.ERR_BULKIFIED_NOT_SUPPORTED, testName + ' #2.1 > Expected ERR_BULKIFIED_NOT_SUPPORTED Exception, got ' + e.getMessage());
            Assert.areEqual(e.errorSource, YS_INVOCABLE_VisualForceToPDF.CLASS_NAME, testName + ' #2.2 > Unexpected error source, got ' + e.errorSource);
        }
        test.stopTest();
    }

    @isTest
    public static void testPDFGenerationWithParents()
    {
        // variable initialization
        String testName = 'testPDFGenerationWithParents';
        YS_SignatureRequest__c sr = YS_DataTestFactory.createSignatureRequest();
        insert sr;
        YS_Signer__c sg = YS_DataTestFactory.createSigner(sr.Id);
        insert sg;

        // inputs
        YS_INVOCABLE_VisualForceToPDF.VisualForceToPDFInput input = new YS_INVOCABLE_VisualForceToPDF.VisualForceToPDFInput();
        input.filename = 'pdfFile';
        input.parentIds = new List<String>{ sr.Id, sg.Id };
        input.pageName = 'MyFakePage'; //As we can't do a test with a real page, due to getContentAsPDF being non supported in test method

        // Actual test
        Test.startTest();
        List<String> lstCDId = YS_INVOCABLE_VisualForceToPDF.generatePDF(new List<YS_INVOCABLE_VisualForceToPDF.VisualForceToPDFInput>{input});
        Test.stopTest();

        // Asserts
        String cdId = lstCDId[0];
        List<ContentDocumentLink> lstCDL = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :cdId ORDER BY LinkedEntityId ASC];
        Set<String> expectedLinkedEntities = new Set<String>{ sr.Id, sg.Id, UserInfo.getUserId() };
        Set<String> alreadyLinkedEntities = new Set<String>();
        for(Integer i = 0; i < lstCDL.size(); i++)
        {
            Assert.isTrue(
                expectedLinkedEntities.contains(lstCDL[i].LinkedEntityId),
                testName + ' #2.' + i + (
                    alreadyLinkedEntities.contains(lstCDL[i].LinkedEntityId) ?
                    ' > Document linked multiple times to '
                    : ' > Expected document to be linked to '
                ) + lstCDL[i].LinkedEntityId);
            expectedLinkedEntities.remove(lstCDL[i].LinkedEntityId);
            alreadyLinkedEntities.add(lstCDL[i].LinkedEntityId);
        }
    }
}