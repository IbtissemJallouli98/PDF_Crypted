/**
 * @description       : Generic invocable action that generates a PDF from a visual force page
 * @author            : ctixier
 * @group             : UTIL-INVOCABLE
 * @last modified on  : 2022-07-01
 * @last modified by  : ctixier
 * @testCoverage      : YS_INVOCABLE_VisualForceToPDF_Test
**/
public with sharing class YS_INVOCABLE_VisualForceToPDF {
    @testVisible private static final String CLASS_NAME = 'YS_INVOCABLE_VisualForceToPDF';

    /**
    * @description Generate a PDF from a target visual force (with param), and link it to all targent parent records
    * @author ctixier | 2022-07-01 
    * @param inputs all inputs needed for PDF generation and storage (filename, url, parentIds)
    * @return List<String> List of content document inserted
    **/
    @InvocableMethod(
        label='[YS] Generate PDF'
        description='Generate and store PDF from target Visual Force page'
        category='YS'
        iconName='slds:standard:document'
        callout='false'
    )
    public static List<String> generatePDF(List<VisualForceToPDFInput> inputs)
    {
        /*ERROR MANAGEMENT*/
        if(inputs == null)
        {
            throw new YS_Utils.WrappedException(YS_Utils.ERR_NULL_PARAM, CLASS_NAME);
        }
        if(inputs.size() > 1)
        {
            throw new YS_Utils.WrappedException(YS_Utils.ERR_BULKIFIED_NOT_SUPPORTED, CLASS_NAME);
        }
        /*END OF ERROR MANAGEMENT*/

        //Get PDF Content - fake if test, as getContentAsPDF is not supported in test methods
        PageReference pdfExportedPage = new PageReference('/apex/' + inputs[0].pageName);
        Blob pdfContent = Test.isRunningTest() ? blob.valueOf('Unit.Test') : pdfExportedPage.getContentAsPDF();
        
        

        //Create content version
        ContentVersion cv = new ContentVersion();
        cv.VersionData = pdfContent;
        cv.Title = inputs[0].filename;
        cv.ContentLocation = 's';
        cv.PathOnClient = inputs[0].filename + '.pdf';
        insert cv;

        //manage content document link(s)
        List<ContentDocumentLink> lstCDL = new List<ContentDocumentLink>();
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        //manage additionnal parents
        if (inputs[0].parentIds != null) {
            for(String recordId : inputs[0].parentIds)
            {
                //attach the document to the target parent
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = docId;
                cdl.LinkedEntityId = recordId;
                cdl.ShareType = 'I';
                cdl.Visibility = 'AllUsers';
                lstCDL.add(cdl);
            }
            insert lstCDL;
        }
        //Return contentDocumentId
        return new List<String>{docId};
    }

    public class VisualForceToPDFInput
    {
        @InvocableVariable(Required = false description='Collection of records Ids the PDF should be also attached to')
        public List<String> parentIds;
        @InvocableVariable(Required = true description='Title of the document, no extension needed')
        public String filename;
        @InvocableVariable(Required = true description='Target visualforce page. Put everything after /apex/ here with needed parameters.')
        public String pageName;
    }
}